import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/presentation/widgets/components/habit_metric_item.dart';

void main() {
  Widget buildTestWidget({
    IconData icon = Icons.local_fire_department,
    Color iconColor = Colors.orange,
    String label = 'Current streak',
    String value = '14 days',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: HabitMetricItem(
            icon: icon,
            iconColor: iconColor,
            label: label,
            value: value,
          ),
        ),
      ),
    );
  }

  group('HabitMetricItem', () {
    testWidgets('renders icon, label, and value with MergeSemantics', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byType(MergeSemantics), findsOneWidget);
    });
  });
}
