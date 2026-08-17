
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Weight record integration with Apple HealthKit and Android Health Connect.
///
/// An abstraction over platform-specific checks.
///
///// Allows mocking platform behavior in tests without modifying global state.
abstract class PlatformDetector {
  /// Whether the app is running on Android.
  bool get isAndroid;

  /// Whether the app is running on iOS.
  bool get isIOS;
}

///// A default implementation using `dart:io`.
class NativePlatformDetector implements PlatformDetector {
  @override
  bool get isAndroid => Platform.isAndroid;
  @override
  bool get isIOS => Platform.isIOS;
}

/// An abstraction over the native health data platform.
///
/// Exposes a platform-neutral API for querying and modifying body weight
/// records backed by Apple HealthKit (iOS) or Google Health Connect (Android),
///// hiding the underlying plugin details from the rest of the app.
abstract class HealthService {
  ///// Checks if HealthKit (iOS) or Health Connect (Android) is available on the device.
  Future<bool> isHealthApiAvailable();

  ///// Checks if read/write permissions for WEIGHT are already granted.
  Future<bool> hasPermissions();

  ///// Requests native OS permissions for WEIGHT (Read & Write).
  Future<bool> requestPermissions();

  ///// Opens native app system settings so the user can manage permissions manually.
  Future<bool> openSystemSettings();

  /// Opens the Google Play Store listing for Health Connect on Android.
  ///
  /// Intended for devices where [isHealthApiAvailable] reports `false`; a
  ///// no-op on other platforms.
  Future<void> installHealthConnect();

  /// Fetches weight entries within a date range.
  ///
  /// Only readings between 20 kg and 300 kg are returned; out-of-range or
  /// non-numeric points are discarded. Entries are sorted newest first.
  ///
  /// @param start Inclusive start of the query window.
  /// @param end Inclusive end of the query window.
  ///// Returns an empty list on failure.
  Future<List<WeightEntry>> fetchWeightHistory({
    required DateTime start,
    required DateTime end,
  });

  /// Writes a weight entry to HealthKit / Health Connect.
  ///
  /// @param weightKg Weight value in kilograms.
  ///// @param timestamp Instant the measurement was recorded.
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
  ///// @param timestamp Instant the entry to delete was recorded.
  Future<bool> deleteWeight({
    required double weightKg,
    required DateTime timestamp,
  });
}

/// A native implementation of [HealthService] backed by the `health` plugin.
///
/// All plugin calls are wrapped in try-catch blocks so missing Health Connect
/// installations, revoked permissions, or platform errors degrade to `false`
/// or an empty result instead of throwing unhandled exceptions. Permission
/// and settings calls are additionally bounded by a five-second timeout
/// ([_operationTimeout]) whose expiry is treated as a failure.
///
/// ## Platform integration
/// On iOS the plugin talks to HealthKit; on Android it talks to Health Connect
/// (which must be installed separately, see [installHealthConnect]). The
/// exchanged data model is [WeightEntry], always expressed in kilograms and
/// mapped 1-to-1 onto the `WEIGHT` health data type requested with both read
/// and write access ([_readWriteAccess]).
///
/// ## Permission flow
/// Reading and writing weight data requires the user to grant health
/// permissions through the native OS authorization prompt
/// ([requestPermissions]); [hasPermissions] reports the current grant state
/// (on iOS only the WRITE grant is disclosed by HealthKit), and
/// [openSystemSettings] lets the user adjust the grant later from the system
///// settings app.
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

  /// The data type used for every weight interaction.
  static const HealthDataType _weightType = HealthDataType.WEIGHT;

  /// The unit used for every weight interaction.
  static const HealthDataUnit _weightUnit = HealthDataUnit.KILOGRAM;

  /// The data types corresponding 1-to-1 with [_readWriteAccess].
  static const List<HealthDataType> _weightTypesReadWrite = [
    HealthDataType.WEIGHT,
    HealthDataType.WEIGHT,
  ];

  /// The read and write access requested for weight records.
  static const List<HealthDataAccess> _readWriteAccess = [
    HealthDataAccess.READ,
    HealthDataAccess.WRITE,
  ];

  /// The match tolerance in kilograms when locating an entry for deletion.
  static const double _deleteWeightToleranceKg = 0.01;

  /// The half-width of the lookup window around the deletion timestamp.
  static const Duration _deleteLookupWindow = Duration(minutes: 1);

  /// The lower bound for a plausible weight reading in kilograms.
  static const double _minWeightKg = 20.0;

  /// The upper bound for a plausible weight reading in kilograms.
  static const double _maxWeightKg = 300.0;

  /// The maximum time allowed for permission and settings calls before fallback.
  static const Duration _operationTimeout = Duration(seconds: 5);

  /// The package name of the official Google Health Connect app.
  static const String _healthConnectPackageId =
      'com.google.android.apps.healthdata';

  /// The Play Store deep link for the Health Connect app.
  static final Uri _healthConnectMarketUri = Uri.parse(
    'market://details?id=$_healthConnectPackageId',
  );

  /// The web fallback for devices without a `market://` handler.
  static final Uri _healthConnectPlayStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$_healthConnectPackageId',
  );

  /// The underlying `health` plugin instance.
  final Health _health;

  /// A platform detector for testing.
  final PlatformDetector _platformDetector;

  /// Whether [_health.configure] has completed successfully at least once.
  ///
  /// The plugin requires a one-time configuration before any other API call;
  /// the flag makes [_ensureConfigured] idempotent so the first call on each
  /// public method initializes the plugin without repeated device-info lookups.
  bool _isConfigured = false;

  /// Configures the health plugin exactly once before the first plugin call.
  ///
  /// A configuration failure never throws: it is logged in debug builds and
  /// the plugin is simply left unconfigured, letting every public method
  ///// degrade gracefully through its own error handling.
  Future<void> _ensureConfigured() async {
    if (!_isConfigured) {
      try {
        await _health.configure();
        _isConfigured = true;
        if (kDebugMode) {
          debugPrint('[HealthService] Health plugin configured successfully.');
        }
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint(
            '[HealthService] Health plugin configuration error: $e\n$stack',
          );
        }
      }
    }
  }

  /// Reports whether the native health platform is reachable on this device.
  ///
  /// Returns `true` unconditionally on iOS (HealthKit is always present) and
  /// probes the Health Connect SDK status on Android. Any plugin error
  /// degrades to `false`.
  @override
  Future<bool> isHealthApiAvailable() async {
    try {
      if (!_platformDetector.isAndroid) {
        // HealthKit is available on every iOS device.
        return true;
      }
      await _ensureConfigured();
      final sdkStatus = await _health.getHealthConnectSdkStatus();
      if (kDebugMode) {
        debugPrint('[HealthService] Health Connect SDK Status: $sdkStatus');
      }
      return sdkStatus == HealthConnectSdkStatus.sdkAvailable;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] isHealthApiAvailable error: $e\n$stack');
      }
      return false;
    }
  }

  /// Checks whether weight read/write permissions were already granted.
  ///
  /// On iOS only the WRITE grant is checked, because HealthKit does not expose
  /// READ grant status. Calls are subject to [_operationTimeout]; a timeout
  /// or plugin error degrades to `false`.
  @override
  Future<bool> hasPermissions() async {
    try {
      await _ensureConfigured();
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
          .hasPermissions(_weightTypesReadWrite, permissions: _readWriteAccess)
          .timeout(_operationTimeout);
      return granted ?? false;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] hasPermissions error: $e\n$stack');
      }
      return false;
    }
  }

  /// Requests native OS permissions for weight read/write access.
  ///
  /// On iOS the result is verified through [hasPermissions], because the
  /// plugin only reports whether the authorization prompt was shown. Calls are
  /// subject to [_operationTimeout]; a timeout or plugin error degrades to
  /// `false`.
  @override
  Future<bool> requestPermissions() async {
    try {
      if (kDebugMode) {
        debugPrint('[HealthService] Requesting permissions for WEIGHT...');
      }
      await _ensureConfigured();
      final bool granted;
      try {
        granted = await _health
            .requestAuthorization(
              _weightTypesReadWrite,
              permissions: _readWriteAccess,
            )
            .timeout(_operationTimeout);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HealthService] Native Auth Exception: $e');
        }
        return false;
      }
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

  /// Opens the app entry in the native system settings.
  ///
  /// Subject to [_operationTimeout]; a timeout or failure to launch the
  /// settings app degrades to `false`.
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

  /// Opens the Google Play Store listing for Health Connect on Android.
  ///
  /// Attempts the `market://` deep link first and falls back to the web Play
  /// Store URL when no market handler is installed. A no-op on other
  /// platforms; any launch failure degrades to doing nothing.
  @override
  Future<void> installHealthConnect() async {
    if (!_platformDetector.isAndroid) {
      return;
    }
    try {
      final marketLaunched = await launchUrl(_healthConnectMarketUri);
      if (!marketLaunched) {
        await launchUrl(
          _healthConnectPlayStoreUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] installHealthConnect error: $e\n$stack');
      }
    }
  }

  /// Fetches and filters weight entries within an inclusive date window.
  ///
  /// Non-numeric points and readings outside the plausible 20-300 kg range are
  /// discarded; surviving entries are sorted newest first. Any plugin error
  /// degrades to an empty list.
  ///
  /// @param start Inclusive start of the query window.
  /// @param end Inclusive end of the query window.
  @override
  Future<List<WeightEntry>> fetchWeightHistory({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: const [_weightType],
        startTime: start,
        endTime: end,
        preferredUnits: const {_weightType: _weightUnit},
      );
      final entries = <WeightEntry>[];
      for (final point in points) {
        if (point.value is! NumericHealthValue) {
          continue;
        }
        final value = (point.value as NumericHealthValue).numericValue
            .toDouble();
        if (value >= _minWeightKg && value <= _maxWeightKg) {
          entries.add(WeightEntry(weightKg: value, dateTime: point.dateFrom));
        }
      }
      entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return entries;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[HealthService] fetchWeightHistory error: $e\n$stack');
      }
      return const [];
    }
  }

  /// Writes a weight reading as a manually recorded health entry.
  ///
  /// The manual recording method is required on iOS, which only accepts manual
  /// or automatic entries for weight records. Any plugin error degrades to
  /// `false`.
  ///
  /// @param weightKg Weight value in kilograms.
  /// @param timestamp Instant the measurement was recorded.
  @override
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime timestamp,
  }) async {
    try {
      await _ensureConfigured();
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

  /// Deletes the weight entry matching [weightKg] near [timestamp].
  ///
  /// The entry is located within a one-minute window around [timestamp],
  /// tolerating a [_deleteWeightToleranceKg] kg difference, and removed by its
  /// UUID. Returns `false` when no match is found or the plugin call fails.
  ///
  /// @param weightKg Weight value in kilograms of the entry to delete.
  /// @param timestamp Instant the entry to delete was recorded.
  @override
  Future<bool> deleteWeight({
    required double weightKg,
    required DateTime timestamp,
  }) async {
    try {
      await _ensureConfigured();
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
