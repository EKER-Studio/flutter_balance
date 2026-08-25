/// A body-mass-index weight category per the WHO classification.
///
/// The categories use the standard WHO cut-off points of 18.5, 25.0, 30.0,
/// 35.0, and 40.0 kg/m²; each boundary is lower-inclusive.
enum BmiCategory {
  /// BMI below 18.5 kg/m².
  underweight,

  /// BMI from 18.5 to 24.9 kg/m².
  normal,

  /// BMI from 25.0 to 29.9 kg/m².
  overweight,

  /// BMI from 30.0 to 34.9 kg/m² (Class I obesity).
  obeseClass1,

  /// BMI from 35.0 to 39.9 kg/m² (Class II obesity).
  obeseClass2,

  /// BMI of 40.0 kg/m² or above (Class III obesity).
  obeseClass3;

  /// Maps a numeric [bmi] value to its [BmiCategory] using the WHO cut-offs.
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
    if (bmi < 35.0) {
      return BmiCategory.obeseClass1;
    }
    if (bmi < 40.0) {
      return BmiCategory.obeseClass2;
    }
    return BmiCategory.obeseClass3;
  }
}
