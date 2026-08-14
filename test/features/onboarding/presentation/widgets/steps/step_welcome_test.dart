import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_welcome.dart';

void main() {
  Widget buildTestWidget({required VoidCallback onNext}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StepWelcome(onNext: onNext)),
    );
  }

  group('StepWelcome', () {
    testWidgets('renders title, subtitle, and feature cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(onNext: () {}));

      expect(find.text('Welcome to Balance'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.text('Weight & Goal'), findsOneWidget);
      expect(find.text('Privacy & Sync'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('calls onNext when the start button is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(onNext: () => tapped = true));

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('start button is tappable even when scrolled out of view', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(onNext: () {}));

      final button = find.text('Get Started');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Get Started'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });
}
