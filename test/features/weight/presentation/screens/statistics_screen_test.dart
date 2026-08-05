import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/features/weight/presentation/screens/statistics_screen.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  WeightBloc createBloc(WeightState state) {
    final bloc = WeightBloc(repository: repository);
    bloc.emit(state);
    return bloc;
  }

  Widget buildSubject({
    required AppSettingsBloc settingsBloc,
    required WeightBloc weightBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: weightBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('pl'),
        home: StatisticsScreen(),
      ),
    );
  }

  testWidgets('StatisticsScreen renders empty state when no entries exist', (
    tester,
  ) async {
    final settingsBloc = AppSettingsBloc();
    final weightBloc = createBloc(
      const WeightLoaded(
        entries: [],
        filteredEntries: [],
        timePeriod: TimePeriod.week,
        heightCm: null,
      ),
    );

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );

    expect(find.text('Brak danych do analizy'), findsOneWidget);
    expect(find.text('Dodaj pierwszy pomiar'), findsOneWidget);
  });

  testWidgets(
    'StatisticsScreen displays calculated metrics and Bento Grid when entries exist',
    (tester) async {
      final now = DateTime.now();
      // Repository returns entries in descending order (newest first)
      final entries = [
        WeightEntry(id: 3, weightKg: 74.0, dateTime: now),
        WeightEntry(
          id: 2,
          weightKg: 75.0,
          dateTime: now.subtract(const Duration(days: 1)),
        ),
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      // Use filteredEntries: [] to avoid fl_chart rendering issues in test env
      final weightBloc = createBloc(
        WeightLoaded(
          entries: entries,
          filteredEntries: [],
          timePeriod: TimePeriod.week,
          heightCm: null,
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );

      // Check lowest weight (74.0)
      expect(find.text('74.0'), findsOneWidget);
      // Check highest weight (80.0)
      expect(find.text('80.0'), findsOneWidget);
      // Check total progress banner (-6.0 kg)
      expect(find.text('-6.0 kg'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen updates metrics when unit is changed to imperial',
    (tester) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 70.0, dateTime: now)];

      final settingsBloc = AppSettingsBloc();
      final weightBloc = createBloc(
        WeightLoaded(
          entries: entries,
          filteredEntries: entries,
          timePeriod: TimePeriod.week,
          heightCm: null,
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );

      expect(find.text('70.0'), findsWidgets);

      // Switch to imperial units
      settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
      await tester.pumpAndSettle();

      // 70.0 kg is ~154.3 lb
      expect(find.textContaining('154.3'), findsWidgets);
      expect(find.textContaining('lb'), findsWidgets);
    },
  );

  testWidgets('StatisticsScreen calculates a multi-day logging streak', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      for (var i = 0; i < 3; i++)
        WeightEntry(
          id: i + 1,
          weightKg: 70.0,
          dateTime: now.subtract(Duration(days: i)),
        ),
    ];

    final settingsBloc = AppSettingsBloc();
    final weightBloc = createBloc(
      WeightLoaded(
        entries: entries,
        filteredEntries: [],
        timePeriod: TimePeriod.week,
        heightCm: null,
      ),
    );

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );

    expect(find.text('3 dni'), findsOneWidget);
  });

  testWidgets(
    'StatisticsScreen streak starts from yesterday when today is missing',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 70.0,
          dateTime: now.subtract(const Duration(days: 1)),
        ),
        WeightEntry(
          id: 2,
          weightKg: 71.0,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      final weightBloc = createBloc(
        WeightLoaded(
          entries: entries,
          filteredEntries: [],
          timePeriod: TimePeriod.week,
          heightCm: null,
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );

      expect(find.text('2 dni'), findsOneWidget);
    },
  );

  testWidgets('StatisticsScreen streak resets when a day is missing', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      WeightEntry(id: 1, weightKg: 70.0, dateTime: now),
      WeightEntry(
        id: 2,
        weightKg: 71.0,
        dateTime: now.subtract(const Duration(days: 2)),
      ),
    ];

    final settingsBloc = AppSettingsBloc();
    final weightBloc = createBloc(
      WeightLoaded(
        entries: entries,
        filteredEntries: [],
        timePeriod: TimePeriod.week,
        heightCm: null,
      ),
    );

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );

    expect(find.text('1 dzień'), findsOneWidget);
  });

  testWidgets('StatisticsScreen computes monthly compliance over 30 days', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [
      for (var i = 0; i < 5; i++)
        WeightEntry(
          id: i + 1,
          weightKg: 70.0,
          dateTime: now.subtract(Duration(days: i)),
        ),
    ];

    final settingsBloc = AppSettingsBloc();
    final weightBloc = createBloc(
      WeightLoaded(
        entries: entries,
        filteredEntries: [],
        timePeriod: TimePeriod.week,
        heightCm: null,
      ),
    );

    await tester.pumpWidget(
      buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
    );

    // 5 of 30 days -> 17% after rounding
    expect(find.text('17%'), findsOneWidget);
  });
}
