import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';

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
