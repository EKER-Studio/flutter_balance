import 'package:balance/core/presentation/theme/app_theme_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Provides localized labels for [AppThemeMode] values.
extension AppThemeModeX on AppThemeMode {
  /// Returns the human-readable label in the given locale.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      AppThemeMode.system => l10n.system,
      AppThemeMode.light => l10n.light,
      AppThemeMode.dark => l10n.dark,
    };
  }
}
