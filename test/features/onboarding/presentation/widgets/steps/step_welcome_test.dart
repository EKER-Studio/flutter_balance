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
    testWidgets('renders title, subtitle, and feature cards in landscape', (tester) async {
      // Default test orientation is usually landscape-like (800x600)
      await tester.pumpWidget(buildTestWidget(onNext: () {}));

      expect(find.text('Welcome to Balance'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.text('Initial Weight'), findsOneWidget);
      expect(find.text('Target Weight'), findsOneWidget);
      expect(find.text('Health Sync'), findsOneWidget);
      expect(find.text('Daily Reminders'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('renders title, subtitle, and feature cards in portrait', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(onNext: () {}));

      expect(find.text('Welcome to Balance'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.text('Initial Weight'), findsOneWidget);
      expect(find.text('Target Weight'), findsOneWidget);
      expect(find.text('Health Sync'), findsOneWidget);
      expect(find.text('Daily Reminders'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
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
