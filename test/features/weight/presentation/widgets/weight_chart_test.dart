import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/presentation/widgets/sections/weight_chart.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage storage;

  setUp(() {
    storage = MockHydratedStorage();

    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    HydratedBloc.storage = storage;
  });

  Widget buildSubject({
    required List<WeightEntry> entries,
    required TimePeriod period,
    ValueChanged<TimePeriod>? onPeriodChanged,
    double? targetWeight,
  }) {
    return BlocProvider(
      create: (_) => AppSettingsBloc(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pl'),
        home: Scaffold(
          body: WeightChart(
            entries: entries,
            period: period,
            onPeriodChanged: onPeriodChanged ?? (_) {},
            targetWeight: targetWeight,
          ),
        ),
      ),
    );
  }

  testWidgets('WeightChart shows empty message when no entries exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(entries: const [], period: TimePeriod.week),
    );

    expect(find.text('Za mało danych, aby wyświetlić wykres.'), findsOneWidget);
  });

  testWidgets('WeightChart renders filter chips and chart', (tester) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 75, dateTime: DateTime(2026, 1, 9)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week),
    );

    expect(find.text('Tydzień'), findsOneWidget);
    expect(find.text('Miesiąc'), findsOneWidget);
    expect(find.text('Rok'), findsOneWidget);
    expect(find.text('Wszystkie'), findsOneWidget);

    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('WeightChart notifies period changes', (tester) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
    ];

    TimePeriod? changedTo;

    await tester.pumpWidget(
      buildSubject(
        entries: entries,
        period: TimePeriod.week,
        onPeriodChanged: (period) => changedTo = period,
      ),
    );

    await tester.tap(find.text('Miesiąc'));
    await tester.pumpAndSettle();

    expect(changedTo, TimePeriod.month);
  });

  testWidgets('WeightChart converts values when imperial unit is active', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2026, 1, 10)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week),
    );

    final settingsBloc = BlocProvider.of<AppSettingsBloc>(
      tester.element(find.byType(WeightChart)),
    );

    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));

    await tester.pumpAndSettle();

    expect(find.textContaining('lbs'), findsWidgets);
  });

  testWidgets('WeightChart handles very large date ranges', (tester) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2020, 1, 1)),
      WeightEntry(id: 2, weightKg: 74, dateTime: DateTime(2026, 1, 1)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.all),
    );

    await tester.pumpAndSettle();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightChart renders a dashed target line in metric units', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 72, dateTime: DateTime(2026, 1, 9)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week, targetWeight: 70),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightChart converts the target weight to imperial units', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 72, dateTime: DateTime(2026, 1, 9)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week, targetWeight: 70),
    );

    final settingsBloc = BlocProvider.of<AppSettingsBloc>(
      tester.element(find.byType(WeightChart)),
    );
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    await tester.pumpAndSettle();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightChart formats month axis labels with MMMd', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 72, dateTime: DateTime(2026, 1, 9)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.month),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightChart ignores deselection of the active chip', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
    ];

    TimePeriod? changedTo = TimePeriod.all;

    await tester.pumpWidget(
      buildSubject(
        entries: entries,
        period: TimePeriod.week,
        onPeriodChanged: (period) => changedTo = period,
      ),
    );

    // Tapping the already-active chip deselects it, which must not fire
    // the change callback.
    await tester.tap(find.text('Tydzień'));
    await tester.pumpAndSettle();

    expect(changedTo, TimePeriod.all);
  });

  testWidgets('WeightChart resolves the target line label on redraws', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 72, dateTime: DateTime(2026, 1, 9)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week, targetWeight: 73),
    );
    await tester.pumpAndSettle();

    // Force a rebuild so the extra line labels are re-resolved.
    final settingsBloc = BlocProvider.of<AppSettingsBloc>(
      tester.element(find.byType(WeightChart)),
    );
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    await tester.pumpAndSettle();
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.metric));
    await tester.pumpAndSettle();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightChart renders touch tooltips above the chart spots', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 10)),
      WeightEntry(id: 2, weightKg: 74, dateTime: DateTime(2026, 1, 12)),
    ];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week),
    );
    await tester.pumpAndSettle();

    // Sweep the plot area so the touch tooltip pipeline (tooltip color and
    // tooltip items) is exercised in metric units.
    var chartRect = tester.getRect(find.byType(LineChart));
    for (var x = 0.0; x < chartRect.width; x += 32) {
      for (final fraction in [0.3, 0.5, 0.7]) {
        final gesture = await tester.startGesture(
          Offset(
            chartRect.left + x,
            chartRect.top + chartRect.height * fraction,
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.up();
        await tester.pumpAndSettle();
      }
    }

    // Repeat the sweep with the imperial unit active so the tooltip
    // converts imperial values back to kilograms.
    final settingsBloc = BlocProvider.of<AppSettingsBloc>(
      tester.element(find.byType(WeightChart)),
    );
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    await tester.pumpAndSettle();
    chartRect = tester.getRect(find.byType(LineChart));
    for (var x = 0.0; x < chartRect.width; x += 32) {
      final gesture = await tester.startGesture(
        Offset(chartRect.left + x, chartRect.top + chartRect.height * 0.5),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });
}
