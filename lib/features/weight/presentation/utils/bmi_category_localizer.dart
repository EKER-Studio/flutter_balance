import 'package:flutter/material.dart';
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

  /// Returns the base [MaterialColor] associated with this category.
  MaterialColor baseColor() {
    return switch (this) {
      BmiCategory.underweight => Colors.blue,
      BmiCategory.normal => Colors.green,
      BmiCategory.overweight => Colors.orange,
      BmiCategory.obese => Colors.red,
    };
  }

  /// Returns the background fill color for a category chip (15% opacity).
  Color chipBackgroundColor() {
    return baseColor().withValues(alpha: 0.15);
  }

  /// Returns the text/icon color for a category chip, adapting to [isDark].
  Color chipContentColor({required bool isDark}) {
    final base = baseColor();
    return isDark ? base.shade300 : base.shade800;
  }
}
