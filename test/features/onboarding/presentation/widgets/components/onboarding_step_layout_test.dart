import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';

void main() {
  group('OnboardingStepLayout Widget Tests', () {
    testWidgets('renders title, subtitle, content, and footer correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingStepLayout(
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              content: Text('Test Content Body'),
              footer: Text('Test Footer Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Content Body'), findsOneWidget);
      expect(find.text('Test Footer Button'), findsOneWidget);
    });

    testWidgets('supports custom titleWidget and subtitleWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingStepLayout(
              titleWidget: Text('Custom Title Widget'),
              subtitleWidget: Text('Custom Subtitle Widget'),
              content: Text('Body'),
              footer: Text('Footer'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Title Widget'), findsOneWidget);
      expect(find.text('Custom Subtitle Widget'), findsOneWidget);
    });

    testWidgets('anchors footer at bottom of viewport in portrait mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingStepLayout(
              title: 'Step 1',
              subtitle: 'Description',
              content: Text('Short Form'),
              footer: SizedBox(
                key: Key('footer_button'),
                height: 48,
                child: Text('Next'),
              ),
            ),
          ),
        ),
      );

      final footerFinder = find.byKey(const Key('footer_button'));
      expect(footerFinder, findsOneWidget);

      final footerBottom = tester.getBottomRight(footerFinder).dy;
      // In a 960 logical px height viewport with 24px bottom padding, footer bottom is ~936
      expect(footerBottom, greaterThan(850));
    });

    testWidgets('renders gracefully in landscape mode without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingStepLayout(
              title: 'Landscape Step',
              subtitle: 'Landscape Subtitle',
              content: Column(
                children: List.generate(
                  8,
                  (i) => Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.blue,
                    child: Text('Item $i'),
                  ),
                ),
              ),
              footer: const SizedBox(height: 48, child: Text('Next Action')),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Landscape Step'), findsOneWidget);
      expect(find.text('Next Action'), findsOneWidget);
    });
  });
}
