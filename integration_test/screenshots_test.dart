@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
  });

  // All 10 officially supported target locales
  const supportedLocales = <String>[
    'en',
    'de',
    'ja',
    'fr',
    'es',
    'pl',
    'pt',
    'nl',
    'it',
    'ko',
  ];

  group('Automated Multi-Locale Screenshots Generator', () {
    for (final localeCode in supportedLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final testDescription = 'Capture 00_splash [$localeCode] [$themeLabel]';

        testWidgets(testDescription, (WidgetTester tester) async {
          final locale = Locale(localeCode);
          final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: theme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const AppSplashScreen(),
            ),
          );

          // TodayShimmerSkeleton has an infinite repeating animation,
          // so pump explicitly rather than calling pumpAndSettle().
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Take pixel-perfect screenshot and deliver to test driver
          final screenshotName = '$localeCode/00_splash/splash_$themeLabel';
          await binding.takeScreenshot(screenshotName);
        }, tags: 'screenshot');
      }
    }
  });
}
