import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/presentation/screens/app_initialization_error_screen.dart';

void main() {
  testWidgets('AppInitializationErrorScreen renders error text and triggers retry callback',
      (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      AppInitializationErrorScreen(
        error: Exception('Test DB Error'),
        onRetry: () {
          retried = true;
        },
      ),
    );

    expect(find.text('Failed to Start PureWeight'), findsOneWidget);
    expect(find.text('Retry Startup'), findsOneWidget);

    await tester.tap(find.text('Retry Startup'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
