import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';

/// A set of localized display helpers for [BmiCategory].
extension BmiCategoryX on BmiCategory {
  /// Returns the user-facing label for this category using [l10n].
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      BmiCategory.underweight => l10n.bmiCategoryUnderweight,
      BmiCategory.normal => l10n.bmiCategoryNormal,
      BmiCategory.overweight => l10n.bmiCategoryOverweight,
      BmiCategory.obeseClass1 => l10n.bmiCategoryObeseClass1,
      BmiCategory.obeseClass2 => l10n.bmiCategoryObeseClass2,
      BmiCategory.obeseClass3 => l10n.bmiCategoryObeseClass3,
    };
  }

  /// Returns the base [MaterialColor] associated with this category.
  MaterialColor baseColor() {
    return switch (this) {
      BmiCategory.underweight => Colors.blue,
      BmiCategory.normal => Colors.green,
      BmiCategory.overweight => Colors.orange,
      BmiCategory.obeseClass1 => Colors.deepOrange,
      BmiCategory.obeseClass2 => Colors.red,
      BmiCategory.obeseClass3 => Colors.purple,
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
