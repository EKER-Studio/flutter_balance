import 'package:balance/features/weight/domain/repositories/health_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';

/// Summary statistics emitted upon successful completion of a health sync cycle.
class HealthSyncResult {
  /// The UTC timestamp when synchronization completed.
  final DateTime syncTimestamp;

  /// Number of entries fetched from the remote health store.
  final int remoteCount;

  /// Number of local records pushed to the remote health store.
  final int pushedLocalCount;

  const HealthSyncResult({
    required this.syncTimestamp,
    required this.remoteCount,
    required this.pushedLocalCount,
  });
}

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

  /// The lookback window when synchronizing without a previous sync timestamp (2 years).
  static const Duration defaultInitialLookback = Duration(days: 730);

  /// Synchronizes entries between the local database and platform health service.
  ///
  /// Scoped to [startDate] or [lastSyncTime] minus a 1-day overlap window to
  /// ensure delayed remote syncs or clock skews are reconciled. Deduplication
  /// is performed against the local repository using a ±60 s / ±0.05 kg tolerance.
  Future<HealthSyncResult?> sync({
    DateTime? startDate,
    DateTime? lastSyncTime,
  }) async {
    final now = DateTime.now();
    final end = now;
    final start =
        startDate ??
        (lastSyncTime?.subtract(const Duration(days: 1)) ??
            now.subtract(defaultInitialLookback));

    final remoteEntries = await healthService.fetchWeightHistory(
      start: start,
      end: end,
    );

    if (remoteEntries.isNotEmpty) {
      await repository.syncRemoteEntries(remoteEntries);
    }

    final localEntries = await repository.getEntriesBetween(start, end);

    final missingRemoteEntries = localEntries.where((local) {
      final lUtc = local.dateTime.toUtc();
      return !remoteEntries.any((remote) {
        final rUtc = remote.dateTime.toUtc();
        return (remote.weightKg - local.weightKg).abs() <= 0.05 &&
            rUtc.difference(lUtc).inSeconds.abs() <= 60;
      });
    }).toList();

    await Future.forEach(missingRemoteEntries, mirrorWrite);

    return HealthSyncResult(
      syncTimestamp: DateTime.now().toUtc(),
      remoteCount: remoteEntries.length,
      pushedLocalCount: missingRemoteEntries.length,
    );
  }

  /// Best-effort write to the platform health service when sync is enabled.
  Future<void> mirrorWrite(WeightEntry entry) async {
    await healthService.writeWeight(
      weightKg: entry.weightKg,
      timestamp: entry.dateTime,
    );
  }

  /// Best-effort delete from the platform health service when sync is enabled.
  Future<void> mirrorDelete(double weightKg, DateTime timestamp) async {
    await healthService.deleteWeight(weightKg: weightKg, timestamp: timestamp);
  }
}
