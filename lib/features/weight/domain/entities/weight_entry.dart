import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

/// Domain entity representing an individual body weight measurement.
///
/// Encapsulates core domain data for weight tracking, including weight in kilograms,
/// measurement timestamp,
/// and an optional user note.
class WeightEntry {
  /// Unique database primary key identifier, defaulting to 0 for unpersisted entries.
  final int id;

  /// Recorded body weight value in kilograms.
  final double weightKg;

  /// Pre-calculated Body Mass Index (BMI), derived from [weightKg] and user height in meters.

  /// Date and time when the weight measurement was recorded.
  final DateTime dateTime;

  /// Optional user-provided text note accompanying the weight record.
  final String? note;

  /// Pre-calculated Body Mass Index (BMI), can be null if not computed.
  final double? bmi;

  /// Creates an immutable [WeightEntry] domain model instance.
  ///
  /// The [weightKg] and [dateTime] parameters are mandatory.
  /// Parameter [id] defaults to 0 for new unsaved entries.
  /// Parameter [note] is optional.
  /// Parameter [bmi] is optional and may be omitted.
  const WeightEntry({
    this.id = 0,
    required this.weightKg,
    required this.dateTime,
    this.note,
    this.bmi,
  });

  /// Uses the standard formula: `BMI = weightKg / (heightMeters * heightMeters)`.
  /// Returns the calculated BMI as a [double].
  static double calculateBmi(double weightKg, double heightMeters) {
    return weightKg / (heightMeters * heightMeters);
  }

  /// Creates a [WeightEntry] with BMI automatically computed from user [heightMeters].
  ///
  /// Takes [id], [weightKg], [heightMeters], [dateTime], and optional [note].
  /// Returns a new [WeightEntry] instance containing the computed [bmi].
}

/// Utility formatting extensions on [WeightEntry] for presentation conversion.
extension WeightEntryFormatting on WeightEntry {
  /// Formats [weightKg] into a display string based on the active [unit] measurement system.
  ///
  /// Converts raw kilogram value to [unit] system (kilograms or pounds) and appends the appropriate unit symbol suffix.
  String formattedWeight(MeasurementUnit unit) => formatWeight(weightKg, unit);

  /// Formats the entity's [bmi] value into a rounded string representation.
  /// Returns a [String] formatted to one decimal place, or `null` if [bmi] is not present.
}
