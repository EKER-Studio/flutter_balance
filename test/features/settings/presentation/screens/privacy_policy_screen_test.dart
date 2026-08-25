import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget createTestWidget({Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrivacyPolicyScreen(),
    );
  }

  testWidgets('renders PrivacyPolicyScreen in English', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('100% Local-First'), findsOneWidget);
    expect(
      find.textContaining('1. Local-First & Zero Account Model'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('contact@ekerstudio.com'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.textContaining('7. Contact Us'), findsOneWidget);
    expect(find.text('contact@ekerstudio.com'), findsOneWidget);
  });

  testWidgets('renders PrivacyPolicyScreen in Polish', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('pl')));
    await tester.pumpAndSettle();

    expect(find.text('Polityka prywatności'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('100% Local-First'), findsOneWidget);
    expect(
      find.textContaining('1. Architektura Local-First i brak konta'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('contact@ekerstudio.com'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.textContaining('7. Kontakt z nami'), findsOneWidget);
    expect(find.text('contact@ekerstudio.com'), findsOneWidget);
  });
}
