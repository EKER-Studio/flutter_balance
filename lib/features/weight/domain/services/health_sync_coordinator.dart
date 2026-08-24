import 'dart:async';

import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';

/// Coordinates two-way synchronization between the local [WeightRepository] and
/// the platform health service (Apple Health / Health Connect).
class HealthSyncCoordinator {
  final HealthService healthService;
  final WeightRepository repository;

  /// Creates a [HealthSyncCoordinator] wrapping the health integration and repository.
  const HealthSyncCoordinator({
    required this.healthService,
    required this.repository,
  });

  /// Synchronizes entries between the local database and platform health service.
  ///
  /// Scoped to [startDate] or [lastSyncTime] minus a 1-day overlap window to
  /// ensure delayed remote syncs or clock skews are reconciled. Deduplication
  /// is performed against the local repository using a ±60 s / ±0.05 kg tolerance.
  Future<void> sync({
    required AppSettingsBloc settingsBloc,
    DateTime? startDate,
    DateTime? lastSyncTime,
  }) async {
    try {
      final now = DateTime.now();
      final end = now;
      final start =
          startDate ??
          (lastSyncTime?.subtract(const Duration(days: 1)) ??
              now.subtract(const Duration(days: 30)));

      final remoteEntries = await healthService.fetchWeightHistory(
        start: start,
        end: end,
      );

      if (remoteEntries.isNotEmpty) {
        await repository.syncRemoteEntries(remoteEntries);
      }

      final localEntries = (await repository.getAllEntries())
          .where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end))
          .toList();

      final missingRemoteEntries = localEntries.where((local) {
        final lUtc = local.dateTime.toUtc();
        return !remoteEntries.any((remote) {
          final rUtc = remote.dateTime.toUtc();
          return (remote.weightKg - local.weightKg).abs() <= 0.05 &&
              rUtc.difference(lUtc).inSeconds.abs() <= 60;
        });
      }).toList();

      if (missingRemoteEntries.isNotEmpty) {
        unawaited(
          Future.forEach(
            missingRemoteEntries,
            (entry) => mirrorWrite(entry),
          ),
        );
      }

      settingsBloc.add(UpdateLastHealthSyncTimestamp(DateTime.now().toUtc()));
      AppAnalytics.logHealthSyncSuccess(
        remoteCount: remoteEntries.length,
        pushedLocalCount: missingRemoteEntries.length,
      );
    } catch (e, stack) {
      AppAnalytics.logHealthSyncFailed(e.toString());
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[HealthSyncCoordinator] Health sync background failure',
        fatal: false,
      );
    }
  }

  /// Best-effort write to the platform health service when sync is enabled.
  Future<void> mirrorWrite(WeightEntry entry) async {
    try {
      await healthService.writeWeight(
        weightKg: entry.weightKg,
        timestamp: entry.dateTime,
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[HealthSyncCoordinator] Health mirror write failed',
        fatal: false,
      );
    }
  }

  /// Best-effort delete from the platform health service when sync is enabled.
  Future<void> mirrorDelete(double weightKg, DateTime timestamp) async {
    try {
      await healthService.deleteWeight(
        weightKg: weightKg,
        timestamp: timestamp,
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[HealthSyncCoordinator] Health mirror delete failed',
        fatal: false,
      );
    }
  }
}
