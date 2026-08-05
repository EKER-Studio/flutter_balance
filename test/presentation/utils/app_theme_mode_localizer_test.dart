import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/l10n/app_localizations_en.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/utils/app_theme_mode_localizer.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('AppThemeModeX.localizedName', () {
    test('maps system to the localized system label', () {
      expect(AppThemeMode.system.localizedName(l10n), l10n.system);
    });

    test('maps light to the localized light label', () {
      expect(AppThemeMode.light.localizedName(l10n), l10n.light);
    });

    test('maps dark to the localized dark label', () {
      expect(AppThemeMode.dark.localizedName(l10n), l10n.dark);
    });

    test('returns distinct labels for distinct modes', () {
      final labels = AppThemeMode.values
          .map((m) => m.localizedName(l10n))
          .toSet();
      expect(labels.length, AppThemeMode.values.length);
    });
  });
}
