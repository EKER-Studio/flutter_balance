import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';

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
