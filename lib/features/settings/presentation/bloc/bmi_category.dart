/// A body-mass-index weight category per the WHO classification.
///
/// The categories use the standard WHO cut-off points of 18.5, 25.0 and
/// 30.0 kg/m²; each boundary is lower-inclusive, so 18.5 falls in [normal]
/// and 30.0 falls in [obese]. The localized display name is exposed by the
/// `localizedName` extension from `bmi_category_localizer.dart`.
enum BmiCategory {
  /// BMI below 18.5 kg/m².
  underweight,

  /// BMI from 18.5 to 24.9 kg/m².
  normal,

  /// BMI from 25.0 to 29.9 kg/m².
  overweight,

  /// BMI of 30.0 kg/m² or above.
  obese;

  /// Maps a numeric [bmi] value to its [BmiCategory] using the WHO cut-offs,
  /// with `underweight < 18.5 <= normal < 25.0 <= overweight < 30.0 <= obese`.
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
