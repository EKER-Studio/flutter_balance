/// Domain entity representing an individual body weight measurement.
///
/// Encapsulates core domain data for weight tracking, including weight in kilograms,
/// measurement timestamp, and an optional user note.
class WeightEntry {
  /// Unique database primary key identifier, defaulting to 0 for unpersisted entries.
  final int id;

  /// Recorded body weight value in kilograms.
  final double weightKg;

  /// Date and time when the weight measurement was recorded.
  final DateTime dateTime;

  /// Optional user-provided text note accompanying the weight record.
  final String? note;

  /// Creates an immutable [WeightEntry] domain entity instance.
  ///
  /// The [weightKg] and [dateTime] parameters are mandatory.
  /// Parameter [id] defaults to 0 for new unsaved entries.
  /// Parameter [note] is optional.
  const WeightEntry({
    this.id = 0,
    required this.weightKg,
    required this.dateTime,
    this.note,
  });

  /// Calculates Body Mass Index (BMI) using body weight in kilograms and height in meters.
  ///
  /// Takes [weightKg] in kilograms and [heightMeters] in meters.
  /// Uses formula: `BMI = weightKg / (heightMeters * heightMeters)`.
  /// Returns calculated BMI as a [double] or [double.infinity] if [heightMeters] is zero.
  static double calculateBmi(double weightKg, double heightMeters) {
    return weightKg / (heightMeters * heightMeters);
  }
}
