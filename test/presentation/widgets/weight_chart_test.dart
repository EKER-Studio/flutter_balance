import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';

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

  testWidgets('WeightChart renders filter chips and chart for entries', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      WeightEntry(id: 1, weightKg: 74.0, dateTime: now),
      WeightEntry(
        id: 2,
        weightKg: 75.0,
        dateTime: now.subtract(const Duration(days: 1)),
      ),
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

  testWidgets('WeightChart notifies period changes via callback', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [WeightEntry(id: 1, weightKg: 74.0, dateTime: now)];
    TimePeriod? changedTo;

    await tester.pumpWidget(
      buildSubject(
        entries: entries,
        period: TimePeriod.week,
        onPeriodChanged: (p) => changedTo = p,
      ),
    );

    await tester.tap(find.text('Miesiąc'));
    expect(changedTo, TimePeriod.month);
  });

  testWidgets('WeightChart converts values when imperial unit is active', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [WeightEntry(id: 1, weightKg: 70.0, dateTime: now)];

    await tester.pumpWidget(
      buildSubject(entries: entries, period: TimePeriod.week),
    );

    // Switch to imperial while the chart is mounted.
    final settingsBloc = BlocProvider.of<AppSettingsBloc>(
      tester.element(find.byType(WeightChart)),
    );
    settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
    await tester.pump();

    expect(find.textContaining('lbs'), findsWidgets);
  });
}
