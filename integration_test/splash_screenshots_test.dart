@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  group('00_splash Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        testWidgets('Capture 00_splash [$localeCode] [$themeLabel]', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: theme,
              themeMode: themeMode,
              home: ScreenshotDeviceFrame(
                isDark: isDark,
                child: const AppSplashScreen(),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          await binding.takeScreenshot(
            '$prefix$localeCode/00_splash/splash_$themeLabel',
          );
        }, tags: 'screenshot');
      }
    }
  });
}
