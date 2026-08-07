import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Abstraction over platform-specific checks.
///
/// Allows mocking platform behavior in tests without modifying global state.
abstract class PlatformDetector {
  /// Returns true if running on Android.
  bool get isAndroid;

  /// Returns true if running on iOS.
  bool get isIOS;
}

/// Default implementation using [dart:io].
class NativePlatformDetector implements PlatformDetector {
  @override
  bool get isAndroid => Platform.isAndroid;
  @override
  bool get isIOS => Platform.isIOS;
}

/// Abstraction over the native health data platform.
///
/// Exposes a platform-neutral API for querying and modifying body weight
/// records backed by Apple HealthKit (iOS) or Google Health Connect (Android),
/// hiding the underlying plugin details from the rest of the app.
abstract class HealthService {
  /// Checks if HealthKit (iOS) or Health Connect (Android) is available on the device.
  Future<bool> isHealthApiAvailable();

  /// Checks if read/write permissions for WEIGHT are already granted.
  Future<bool> hasPermissions();

  /// Requests native OS permissions for WEIGHT (Read & Write).
  Future<bool> requestPermissions();

  /// Opens native app system settings so the user can manage permissions manually.
  Future<bool> openSystemSettings();

  /// Fetches weight entries within a date range.
  ///
  /// @param start Inclusive start of the query window.
  /// @param end Inclusive end of the query window.
  /// Returns entries sorted newest first, or an empty list on failure.
  Future<List<WeightEntry>> fetchWeightHistory({
    required DateTime start,
    required DateTime end,
  });

  /// Writes a weight entry to HealthKit / Health Connect.
  ///
  /// @param weightKg Weight value in kilograms.
  /// @param timestamp Instant the measurement was recorded.
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime timestamp,
  });

  /// Deletes a weight entry from HealthKit / Health Connect if supported.
  ///
  /// Deletes the entry matching [weightKg] within the minute around
  /// [timestamp] on a best-effort basis.
  ///
  /// @param weightKg Weight value in kilograms of the entry to delete.
  /// @param timestamp Instant the entry to delete was recorded.
  Future<bool> deleteWeight({
    required double weightKg,
    required DateTime timestamp,
  });
}

/// Native implementation of [HealthService] backed by the `health` plugin.
///
/// All plugin calls are wrapped in try-catch blocks so missing Health Connect
/// installations, revoked permissions, or platform errors degrade to `false`
/// or an empty result instead of throwing unhandled exceptions.
class NativeHealthService implements HealthService {
  /// Creates a service wrapping [health], which defaults to a fresh plugin instance.
  ///
  /// @param health Optional plugin instance, useful for tests.
  /// @param platformDetector Platform detector, defaults to native implementation.
  NativeHealthService({Health? health, PlatformDetector? platformDetector})
    : _health = health ?? Health(),
      _platformDetector = platformDetector ?? NativePlatformDetector();

  /// The single shared instance of [NativeHealthService].
  static final NativeHealthService instance = NativeHealthService();

  /// Data type used for every weight interaction.
  static const HealthDataType _weightType = HealthDataType.WEIGHT;

  /// Unit used for every weight interaction.
  static const HealthDataUnit _weightUnit = HealthDataUnit.KILOGRAM;

  /// Read and write access requested for weight records.
  static const List<HealthDataAccess> _readWriteAccess = [
    HealthDataAccess.READ,
    HealthDataAccess.WRITE,
  ];

  /// Match tolerance in kilograms when locating an entry for deletion.
  static const double _deleteWeightToleranceKg = 0.01;

  /// Half-width of the lookup window around the deletion timestamp.
  static const Duration _deleteLookupWindow = Duration(minutes: 1);

  /// Maximum time allowed for permission and settings calls before fallback.
  static const Duration _operationTimeout = Duration(seconds: 5);

  /// The underlying `health` plugin instance.
  final Health _health;

  /// Platform detector for testing.
  final PlatformDetector _platformDetector;

  @override
  Future<bool> isHealthApiAvailable() async {
    try {
      if (!_platformDetector.isAndroid) {
        // HealthKit is available on every iOS device.
        return true;
      }
      return await _health.isHealthConnectAvailable();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] isHealthApiAvailable error: $e\n$stack');
      }
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    try {
      if (_platformDetector.isIOS) {
        // HealthKit intentionally does not disclose READ grants, so the WRITE
        // grant is the only reliable signal that the app is authorized.
        final writeGranted = await _health
            .hasPermissions(
              const [_weightType],
              permissions: const [HealthDataAccess.WRITE],
            )
            .timeout(_operationTimeout);
        return writeGranted ?? false;
      }
      final granted = await _health
          .hasPermissions(const [_weightType], permissions: _readWriteAccess)
          .timeout(_operationTimeout);
      return granted ?? false;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] hasPermissions error: $e\n$stack');
      }
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final granted = await _health
          .requestAuthorization(const [
            _weightType,
          ], permissions: _readWriteAccess)
          .timeout(_operationTimeout);
      if (!granted) {
        return false;
      }
      if (_platformDetector.isIOS) {
        // On iOS the plugin reports that the prompt was shown, not the actual
        // grant, so the result is verified through [hasPermissions].
        return await hasPermissions();
      }
      return granted;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] requestPermissions error: $e\n$stack');
      }
      return false;
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    try {
      return await openAppSettings().timeout(_operationTimeout);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] openSystemSettings error: $e\n$stack');
      }
      return false;
    }
  }

  @override
  Future<List<WeightEntry>> fetchWeightHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [_weightType],
        startTime: start,
        endTime: end,
        preferredUnits: const {_weightType: _weightUnit},
      );
      final entries = <WeightEntry>[
        for (final point in points)
          if (point.value is NumericHealthValue)
            WeightEntry(
              weightKg: (point.value as NumericHealthValue).numericValue
                  .toDouble(),
              dateTime: point.dateFrom,
            ),
      ];
      entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return entries;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] fetchWeightHistory error: $e\n$stack');
      }
      return const [];
    }
  }

  @override
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime timestamp,
  }) async {
    try {
      return await _health.writeHealthData(
        value: weightKg,
        unit: _weightUnit,
        type: _weightType,
        startTime: timestamp,
        endTime: timestamp,
        // Required on iOS, where only manual or automatic recording methods
        // are accepted for weight records.
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] writeWeight error: $e\n$stack');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteWeight({
    required double weightKg,
    required DateTime timestamp,
  }) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: const [_weightType],
        startTime: timestamp.subtract(_deleteLookupWindow),
        endTime: timestamp.add(_deleteLookupWindow),
        preferredUnits: const {_weightType: _weightUnit},
      );

      HealthDataPoint? match;
      for (final point in points) {
        if (point.value is NumericHealthValue &&
            ((point.value as NumericHealthValue).numericValue - weightKg)
                    .abs() <=
                _deleteWeightToleranceKg) {
          match = point;
          break;
        }
      }
      if (match == null) {
        return false;
      }
      return await _health.deleteByUUID(uuid: match.uuid, type: _weightType);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] deleteWeight error: $e\n$stack');
      }
      return false;
    }
  }
}
