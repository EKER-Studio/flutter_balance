import 'package:pure_weight/l10n/app_localizations.dart';

/// BMI category classification.
enum BmiCategory {
  /// BMI below 18.5.
  underweight,

  /// BMI between 18.5 and 24.9.
  normal,

  /// BMI between 25.0 and 29.9.
  overweight,

  /// BMI 30.0 or above.
  obese;

  /// Maps a numeric BMI value to its corresponding [BmiCategory].
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

/// Localized display helpers for [BmiCategory].
extension BmiCategoryX on BmiCategory {
  /// Returns the user-facing label for this category using [l10n].
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      BmiCategory.underweight => l10n.bmiCategoryUnderweight,
      BmiCategory.normal => l10n.bmiCategoryNormal,
      BmiCategory.overweight => l10n.bmiCategoryOverweight,
      BmiCategory.obese => l10n.bmiCategoryObese,
    };
  }
}
