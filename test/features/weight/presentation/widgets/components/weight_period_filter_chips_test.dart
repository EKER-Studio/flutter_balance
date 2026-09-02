import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/features/weight/presentation/widgets/components/weight_period_filter_chips.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    TimePeriod period = TimePeriod.month,
    ValueChanged<TimePeriod>? onPeriodChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: WeightPeriodFilterChips(
            period: period,
            onPeriodChanged: onPeriodChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('WeightPeriodFilterChips', () {
    testWidgets(
      'renders all TimePeriod filter chips and indicates selected period',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(period: TimePeriod.month));
        await tester.pumpAndSettle();

        expect(find.byType(ChoiceChip), findsNWidgets(4));
        expect(find.text('Week'), findsOneWidget);
        expect(find.text('Month'), findsOneWidget);
        expect(find.text('Year'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);

        final monthChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Month'),
        );
        final weekChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Week'),
        );

        expect(monthChip.selected, isTrue);
        expect(weekChip.selected, isFalse);
      },
    );

    testWidgets('invokes onPeriodChanged when a new chip is selected', (
      tester,
    ) async {
      TimePeriod? selected;
      await tester.pumpWidget(
        buildTestWidget(
          period: TimePeriod.month,
          onPeriodChanged: (p) => selected = p,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();

      expect(selected, equals(TimePeriod.year));
    });
  });
}
