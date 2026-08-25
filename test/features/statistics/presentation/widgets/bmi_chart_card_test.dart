import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_chart_card.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/weight/domain/time_period.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  WeightEntry entry({required double weightKg, required int daysAgo}) {
    return WeightEntry(
      weightKg: weightKg,
      dateTime: now.subtract(Duration(days: daysAgo)),
    );
  }

  Widget buildSubject({
    required List<WeightEntry> entries,
    required double? heightCm,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      home: Scaffold(
        body: BmiChartCard(
          entries: entries,
          heightCm: heightCm,
          period: TimePeriod.week,
          onPeriodChanged: (_) {},
        ),
      ),
    );
  }

  group('without height', () {
    testWidgets('shows the no-height message and a legend button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(entries: [], heightCm: null));

      expect(
        find.text('Set your height in Settings to see the BMI chart.'),
        findsOneWidget,
      );
      expect(find.byTooltip('BMI Categories'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('opens the legend dialog from the help button', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [entry(weightKg: 70, daysAgo: 1)],
          heightCm: null,
        ),
      );

      await tester.tap(find.byTooltip('BMI Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Underweight'), findsOneWidget);
    });
  });

  group('with height but insufficient entries', () {
    testWidgets('shows the empty chart message when there are no entries', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(entries: [], heightCm: 175));

      expect(find.text('Not enough data to display chart.'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('shows the empty chart message with a single entry', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(entries: [entry(weightKg: 70, daysAgo: 0)], heightCm: 175),
      );

      expect(find.text('Not enough data to display chart.'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });
  });

  group('with height and chart data', () {
    testWidgets('renders the line chart with a delta chip', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 75, daysAgo: 10),
            entry(weightKg: 74, daysAgo: 5),
            entry(weightKg: 73, daysAgo: 0),
          ],
          heightCm: 175,
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      // Delta BMI = (73 - 75) / 1.75^2 = -2 / 3.0625 = -0.65 -> -0.7
      expect(find.text('-0.7'), findsOneWidget);
    });

    testWidgets('shows positive delta for increasing BMI', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 50, daysAgo: 5),
            entry(weightKg: 52, daysAgo: 0),
          ],
          heightCm: 175,
        ),
      );

      // Delta BMI = (52 - 50) / 1.75^2 = 2 / 3.0625 = +0.65 -> +0.7
      expect(find.text('+0.7'), findsOneWidget);
    });

    testWidgets('shows zero delta for unchanging BMI', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 85, daysAgo: 5),
            entry(weightKg: 85, daysAgo: 0),
          ],
          heightCm: 175,
        ),
      );

      expect(find.text('0.0'), findsOneWidget);
    });

    testWidgets('renders the delta chip in dark mode', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 75, daysAgo: 5),
            entry(weightKg: 74, daysAgo: 0),
          ],
          heightCm: 175,
          themeMode: ThemeMode.dark,
        ),
      );

      expect(find.text('-0.3'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('opens the legend dialog when tapping the header', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 75, daysAgo: 5),
            entry(weightKg: 74, daysAgo: 0),
          ],
          heightCm: 175,
        ),
      );

      await tester.tap(find.text('-0.3'));
      await tester.pumpAndSettle();

      expect(find.text('BMI Categories'), findsOneWidget);
      expect(find.text('≥ 40.0'), findsOneWidget);
    });

    testWidgets('shows a tooltip with the weight value while the chart is '
        'touched', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            entry(weightKg: 75, daysAgo: 10),
            entry(weightKg: 74, daysAgo: 5),
            entry(weightKg: 73, daysAgo: 0),
          ],
          heightCm: 175,
        ),
      );

      // The middle of the three evenly spaced spots sits at the horizontal
      // centre of the chart leaf (the leaf is inset from the LineChart widget
      // by the axis title margins). Holding past the long-press threshold
      // resolves the gesture arena and triggers the built-in touch handler,
      // which paints the tooltip on the canvas rather than as a widget, so its
      // visibility is asserted through the chart's target data.
      final leafFinder = find.descendant(
        of: find.byType(LineChart),
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'LineChartLeaf',
        ),
      );
      final leafRect = tester.getRect(leafFinder);
      final gesture = await tester.startGesture(leafRect.center);
      await tester.pump(const Duration(milliseconds: 700));

      final chartRender = tester.renderObject(leafFinder) as dynamic;
      expect(
        (chartRender.targetData as dynamic).showingTooltipIndicators,
        isNotEmpty,
      );
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('renders long-range charts spanning more than 180 days', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          entries: [
            for (var i = 0; i < 12; i++)
              entry(weightKg: 70 + (i % 3), daysAgo: i * 30),
          ],
          heightCm: 175,
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
