import 'package:flutter_test/flutter_test.dart';

import 'package:pure_weight/app.dart';

void main() {
  testWidgets('App displays PureWeight MVP scaffold', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('PureWeight MVP'), findsOneWidget);
  });
}
