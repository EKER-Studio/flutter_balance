import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Defines platform-neutral access to weight records stored by a health service.
abstract interface class HealthService {
  /// Reports whether a native health API is available on the current device.
  Future<bool> isHealthApiAvailable();

  /// Reports whether read and write access to weight records is already granted.
  Future<bool> hasPermissions();

  /// Requests native operating-system permission to read and write weight records.
  Future<bool> requestPermissions();

  /// Opens system settings so the user can change health permissions.
  Future<bool> openSystemSettings();

  /// Opens the Health Connect store listing when the service is unavailable.
  Future<void> installHealthConnect();

  /// Reads weight entries in the inclusive date range.
  ///
  /// [start] is the earliest included timestamp.
  /// [end] is the latest included timestamp.
  Future<List<WeightEntry>> fetchWeightHistory({
    required DateTime start,
    required DateTime end,
  });

  /// Writes a weight entry to the native health service.
  ///
  /// [weightKg] is the weight in kilograms.
  /// [timestamp] is the time the measurement was recorded.
  Future<bool> writeWeight({
    required double weightKg,
    required DateTime timestamp,
  });

  /// Deletes a matching weight entry from the native health service.
  ///
  /// [weightKg] is the recorded weight in kilograms.
  /// [timestamp] is the time the measurement was recorded.
  Future<bool> deleteWeight({
    required double weightKg,
    required DateTime timestamp,
  });
}
