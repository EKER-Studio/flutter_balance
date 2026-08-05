import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/presentation/widgets/state_message_card.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onButtonPressed,
    IconData? buttonIcon,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StateMessageCard(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            iconContainerColor: Colors.red.shade100,
            title: 'Something went wrong',
            subtitle: 'Please try again.',
            buttonLabel: 'Retry',
            onButtonPressed: onButtonPressed,
            buttonIcon: buttonIcon,
          ),
        ),
      ),
    );
  }

  testWidgets('renders icon in a circular container with given colors', (
    tester,
  ) async {
    await pumpCard(tester);

    final container = tester.widget<Container>(
      find.ancestor(
        of: find.byIcon(Icons.error_outline),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, Colors.red.shade100);

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, Colors.red);
    expect(icon.size, 48);
  });

  testWidgets('renders title and subtitle text', (tester) async {
    await pumpCard(tester);

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);
  });

  testWidgets('shows button with default add icon and fires callback', (
    tester,
  ) async {
    var pressed = false;
    await pumpCard(tester, onButtonPressed: () => pressed = true);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(pressed, isTrue);
  });

  testWidgets('shows custom button icon when provided', (tester) async {
    await pumpCard(tester, onButtonPressed: () {}, buttonIcon: Icons.refresh);

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('hides the button when label is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StateMessageCard(
            icon: Icons.check,
            iconColor: Colors.green,
            iconContainerColor: Colors.green,
            title: 'Done',
            subtitle: 'All good.',
          ),
        ),
      ),
    );

    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
