/// Pure domain entity representing a weight measurement entry.
class WeightEntry {
  /// Unique identifier, 0 for unsaved entries.
  final int id;

  /// Body weight in kilograms.
  final double weightKg;

  /// Pre-calculated Body Mass Index, derived from weight and height.
  final double? bmi;

  /// Timestamp of the measurement.
  final DateTime dateTime;

  /// Optional user-provided note.
  final String? note;

  /// All fields are required except [id] (auto-assigned) and [note].
  const WeightEntry({
    this.id = 0,
    required this.weightKg,
    this.bmi,
    required this.dateTime,
    this.note,
  });

  /// Calculates BMI from weight in kilograms and height in meters.
  /// Formula: BMI = mass_kg / (height_m^2)
  static double calculateBmi(double weightKg, double heightMeters) {
    return weightKg / (heightMeters * heightMeters);
  }

  /// Creates a [WeightEntry] with BMI auto-calculated from [heightMeters].
  factory WeightEntry.withBmi({
    int id = 0,
    required double weightKg,
    required double heightMeters,
    required DateTime dateTime,
    String? note,
  }) {
    return WeightEntry(
      id: id,
      weightKg: weightKg,
      bmi: calculateBmi(weightKg, heightMeters),
      dateTime: dateTime,
      note: note,
    );
  }
}
