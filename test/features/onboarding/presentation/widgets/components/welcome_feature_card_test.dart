import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/welcome_feature_card.dart';

void main() {
  Widget buildTestWidget({
    IconData icon = Icons.security_rounded,
    String title = '100% Private & Offline',
    bool isLandscape = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: WelcomeFeatureCard(
            icon: icon,
            title: title,
            isLandscape: isLandscape,
          ),
        ),
      ),
    );
  }

  group('WelcomeFeatureCard', () {
    testWidgets('renders title and icon in portrait mode', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('100% Private & Offline'), findsOneWidget);
      expect(find.byIcon(Icons.security_rounded), findsOneWidget);
    });

    testWidgets('renders in landscape mode with adjusted paddings', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(isLandscape: true));
      await tester.pumpAndSettle();

      expect(find.text('100% Private & Offline'), findsOneWidget);
    });
  });
}
