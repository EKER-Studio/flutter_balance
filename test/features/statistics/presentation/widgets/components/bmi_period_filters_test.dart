import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_period_filters.dart';
import 'package:balance/features/weight/domain/time_period.dart';
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
          child: BmiPeriodFilters(
            period: period,
            onPeriodChanged: onPeriodChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('BmiPeriodFilters', () {
    testWidgets('renders week, month, year pills and triggers callback on change', (
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

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(selected, equals(TimePeriod.week));
    });
  });
}
