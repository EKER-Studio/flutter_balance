import 'package:pure_weight/l10n/app_localizations.dart';

/// The app's theme mode preference.
enum AppThemeMode {
  /// Follow the system's appearance.
  system,

  /// Force light theme.
  light,

  /// Force dark theme.
  dark,
}

/// Extension providing localized labels for [AppThemeMode].
extension AppThemeModeX on AppThemeMode {
  /// Human-readable label in the given locale.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      AppThemeMode.system => l10n.system,
      AppThemeMode.light => l10n.light,
      AppThemeMode.dark => l10n.dark,
    };
  }
}
