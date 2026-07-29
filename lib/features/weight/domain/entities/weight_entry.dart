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

  /// Creates an immutable [WeightEntry] domain model instance.
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

  /// Uses the standard formula: `BMI = weightKg / (heightMeters * heightMeters)`.
  /// Returns the calculated BMI as a [double].
  static double calculateBmi(double weightKg, double heightMeters) {
    return weightKg / (heightMeters * heightMeters);
  }
}
