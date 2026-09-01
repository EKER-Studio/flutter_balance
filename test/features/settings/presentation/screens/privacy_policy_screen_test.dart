import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
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

  testWidgets(
    'PrivacyPolicyScreen wraps content with ClampedLayout for tablet & landscape',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final clampedLayoutFinder = find.byType(ClampedLayout);
      expect(clampedLayoutFinder, findsOneWidget);
      final clampedLayout = tester.widget<ClampedLayout>(clampedLayoutFinder);
      expect(
        clampedLayout.maxWidth,
        AppLayoutTokens.maxSingleColumnContentWidth,
      );
    },
  );
}
