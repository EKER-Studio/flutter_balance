@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();

  setUpAll(() async {
    await initScreenshotEnvironment(binding);
  });

  group('06_biometric Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 06_biometric / 01_biometric_lock
        testWidgets(
          'Capture 06_biometric/01_biometric_lock [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateBiometricLock(true))
              ..add(const SetLocked(true));

            await tester.pumpWidget(
              BlocProvider<AppSettingsBloc>.value(
                value: settingsBloc,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    child: const BiometricShieldScreen(),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            await binding.takeScreenshot(
              '$prefix$localeCode/06_biometric/01_biometric_lock_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
