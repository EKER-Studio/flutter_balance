import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_chart_header.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    List<WeightEntry> entries = const [],
    double? heightCm,
    VoidCallback? onLegendTap,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BmiChartHeader(
            entries: entries,
            heightCm: heightCm,
            onLegendTap: onLegendTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('BmiChartHeader', () {
    testWidgets('renders basic title and legend icon when height is null or entries are empty', (
      tester,
    ) async {
      var legendTapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          entries: const [],
          heightCm: null,
          onLegendTap: () => legendTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BMI'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.help_outline));
      expect(legendTapped, isTrue);
    });

    testWidgets('renders computed BMI value and localized category chip', (
      tester,
    ) async {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 75.0,
          dateTime: DateTime(2026, 5, 20),
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(entries: entries, heightCm: 180.0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);
    });
  });
}
