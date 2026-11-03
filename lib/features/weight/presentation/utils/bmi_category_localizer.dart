import 'package:flutter/material.dart';
import 'package:balance/core/presentation/theme/app_feedback_theme.dart';
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

  /// Returns the semantic foreground color associated with this category.
  Color baseColor({required bool isDark}) {
    return switch (this) {
      BmiCategory.underweight => AppFeedbackTheme.infoForegroundFor(
        isDark: isDark,
      ),
      BmiCategory.normal => AppFeedbackTheme.successForegroundFor(
        isDark: isDark,
      ),
      BmiCategory.overweight || BmiCategory.obeseClass1 =>
        AppFeedbackTheme.warningForegroundFor(isDark: isDark),
      BmiCategory.obeseClass2 || BmiCategory.obeseClass3 =>
        AppFeedbackTheme.errorForegroundFor(isDark: isDark),
    };
  }

  /// Returns the theme-aware background fill color for a category chip.
  Color chipBackgroundColor({required bool isDark}) {
    return switch (this) {
      BmiCategory.underweight =>
        isDark
            ? AppFeedbackTheme.infoBackgroundDark
            : AppFeedbackTheme.infoBackgroundLight,
      BmiCategory.normal => AppFeedbackTheme.successBackgroundFor(
        isDark: isDark,
      ),
      BmiCategory.overweight || BmiCategory.obeseClass1 =>
        AppFeedbackTheme.warningBackgroundFor(isDark: isDark),
      BmiCategory.obeseClass2 || BmiCategory.obeseClass3 =>
        isDark
            ? AppFeedbackTheme.errorBackgroundDark
            : AppFeedbackTheme.errorBackgroundLight,
    };
  }

  /// Returns the text/icon color for a category chip, adapting to [isDark].
  Color chipContentColor({required bool isDark}) {
    return baseColor(isDark: isDark);
  }
}
