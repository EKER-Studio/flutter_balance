/// A category classification for a body mass index (BMI).
enum BmiCategory {
  /// A BMI below 18.5.
  underweight,

  /// A BMI between 18.5 and 24.9.
  normal,

  /// A BMI between 25.0 and 29.9.
  overweight,

  /// A BMI 30.0 or above.
  obese;

  /// Maps a numeric [bmi] value to its corresponding [BmiCategory].
  static BmiCategory fromBmi(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    }
    if (bmi < 25.0) {
      return BmiCategory.normal;
    }
    if (bmi < 30.0) {
      return BmiCategory.overweight;
    }
    return BmiCategory.obese;
  }
}
