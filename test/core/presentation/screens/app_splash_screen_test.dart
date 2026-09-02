import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';

void main() {
  Widget buildTestWidget({Locale? locale}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const AppSplashScreen(),
    );
  }

  group('AppSplashScreen', () {
    testWidgets('renders the splash screen with app logo', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(AppSplashScreen), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('exposes the app loading semantics label', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('The app is loading'),
      );
      expect(semantics.textDirection, TextDirection.ltr);

      tester.takeException();
    });

    testWidgets('localizes the loading label to Polish', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('pl')));
      await tester.pump();

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Aplikacja się ładuje'),
      );
      expect(semantics.label, 'Aplikacja się ładuje');

      tester.takeException();
    });
  });
}
