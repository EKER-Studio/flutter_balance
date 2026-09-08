import 'package:balance/features/weight/domain/bmi_category.dart';

/// Pure domain utility for computing Body Mass Index (BMI) values and classifications.
abstract final class BmiCalculator {
  /// Computes the numeric BMI score from metric weight and height.
  ///
  /// @param weightKg Body weight in kilograms.
  /// @param heightCm Stature height in centimeters.
  ///
  /// Returns `0.0` when [heightCm] or [weightKg] is non-positive.
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return 0.0;
    }
    final heightInMeters = heightCm / 100.0;
    return weightKg / (heightInMeters * heightInMeters);
  }

  /// Resolves the corresponding [BmiCategory] for a computed [bmi] value.
  ///
  /// @param bmi Numeric Body Mass Index value.
  static BmiCategory categoryFor({required double bmi}) {
    return BmiCategory.fromBmi(bmi);
  }

  /// Computes the BMI value and resolves its [BmiCategory] directly from measurements.
  ///
  /// @param weightKg Body weight in kilograms.
  /// @param heightCm Stature height in centimeters.
  static BmiCategory categoryForMeasurements({
    required double weightKg,
    required double heightCm,
  }) {
    final bmi = calculate(weightKg: weightKg, heightCm: heightCm);
    return categoryFor(bmi: bmi);
  }
}
