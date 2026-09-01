import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/domain/entities/period_comparison.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/period_comparison_card.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildSubject(
    PeriodComparisonResult comparison, {
    MeasurementUnit unit = MeasurementUnit.metric,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PeriodComparisonCard(
            entries: const [],
            comparisonOverride: comparison,
            unit: unit,
          ),
        ),
      ),
    );
  }

  group('PeriodComparisonCard', () {
    testWidgets('renders empty state message when insufficient data', (
      tester,
    ) async {
      const comparison = PeriodComparisonResult(
        currentPeriod: PeriodSummary(
          startWeight: null,
          endWeight: null,
          netChange: null,
          averageWeight: null,
          entryCount: 0,
          label: 'August',
        ),
        previousPeriod: PeriodSummary(
          startWeight: null,
          endWeight: null,
          netChange: null,
          averageWeight: null,
          entryCount: 0,
          label: 'July',
        ),
        deltaNetChange: null,
        deltaAverage: null,
        deltaEntryCount: 0,
        hasComparisonData: false,
      );

      await tester.pumpWidget(buildSubject(comparison));
      await tester.pumpAndSettle();

      expect(find.text('Period Comparison'), findsOneWidget);
      expect(
        find.text(
          'Log measurements across at least two months to see comparison trends.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders comparison metrics and deltas when data is available',
      (tester) async {
        const comparison = PeriodComparisonResult(
          currentPeriod: PeriodSummary(
            startWeight: 80.0,
            endWeight: 78.0,
            netChange: -2.0,
            averageWeight: 79.0,
            entryCount: 15,
            label: 'August',
          ),
          previousPeriod: PeriodSummary(
            startWeight: 82.0,
            endWeight: 80.0,
            netChange: -2.0,
            averageWeight: 81.0,
            entryCount: 10,
            label: 'July',
          ),
          deltaNetChange: 0.0,
          deltaAverage: -2.0,
          deltaEntryCount: 5,
          hasComparisonData: true,
        );

        await tester.pumpWidget(buildSubject(comparison));
        await tester.pumpAndSettle();

        expect(find.text('Period Comparison'), findsOneWidget);
        expect(find.text('August vs July'), findsOneWidget);
        expect(find.text('Net change'), findsOneWidget);
        expect(find.text('Average Weight'), findsOneWidget);
        expect(find.text('Measurements'), findsOneWidget);
        expect(find.text('+5'), findsOneWidget);
      },
    );
  });
}
