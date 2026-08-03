import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';

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
