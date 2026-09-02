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

  Widget buildSplashWrapper({
    required Locale locale,
    required ThemeData theme,
    required ThemeMode themeMode,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      themeMode: themeMode,
      home: const Scaffold(
        body: SafeArea(child: AppSplashScreen()),
      ),
    );
  }

  group('Automated Multi-Locale Screenshots Generator', () {
    for (final localeCode in supportedLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // ---------------------------------------------------------------------
        // 00_splash (Generated in en/ and across all supported locales)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 00_splash [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildSplashWrapper(
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/00_splash/splash_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
