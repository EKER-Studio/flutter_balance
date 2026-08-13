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
import 'package:balance/features/weight/presentation/widgets/weight_chart.dart';

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
}
