import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/presentation/widgets/components/weight_detail_row.dart';

void main() {
  Widget buildTestWidget({
    IconData icon = Icons.arrow_upward,
    Color iconColor = Colors.red,
    String label = 'Highest',
    String value = '82.5 kg',
    String date = 'Jan 15, 2026',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: WeightDetailRow(
            icon: icon,
            iconColor: iconColor,
            label: label,
            value: value,
            date: date,
          ),
        ),
      ),
    );
  }

  group('WeightDetailRow', () {
    testWidgets('renders label, date, value, and icon with MergeSemantics', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Highest'), findsOneWidget);
      expect(find.text('Jan 15, 2026'), findsOneWidget);
      expect(find.text('82.5 kg'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byType(MergeSemantics), findsOneWidget);
    });
  });
}
