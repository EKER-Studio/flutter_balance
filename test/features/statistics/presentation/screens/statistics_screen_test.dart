import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_chart_card.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

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
    Brightness brightness = Brightness.light,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc),
        BlocProvider.value(value: weightBloc),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pl'),
        home: const StatisticsScreen(),
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

      // Check lowest weight (74.0 kg)
      expect(find.textContaining('74.0'), findsOneWidget);
      // Check highest weight (80.0 kg)
      expect(find.textContaining('80.0'), findsOneWidget);
      // Check total progress banner (-6.0 kg)
      expect(find.textContaining('-6.0 kg'), findsOneWidget);
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

      expect(find.textContaining('70.0'), findsWidgets);

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

  testWidgets('StatisticsScreen computes total compliance over all days', (
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

    // 5 entries over 5 days -> 100%
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets(
    'StatisticsScreen renders consolidated composite cards with all health metrics',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 74.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: now.subtract(const Duration(days: 10)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const UpdateHeight(175.0));
      final weightBloc = createBloc(
        WeightLoaded(
          entries: entries,
          filteredEntries: [],
          timePeriod: TimePeriod.week,
          heightCm: 175.0,
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );
      await tester.pumpAndSettle();

      // Composite card titles & metrics
      expect(find.text('Zakres i średnia wagi'), findsOneWidget);
      expect(find.byType(BmiChartCard), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen pull-to-refresh dispatches SubscribeToWeightChanges',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = WeightEntry(
        id: 1,
        weightKg: 72.5,
        dateTime: DateTime.now(),
      );
      final controller = StreamController<WeightState>.broadcast();
      addTearDown(controller.close);

      final weightBloc = MockWeightBloc();
      when(() => weightBloc.state).thenReturn(
        WeightLoaded(
          entries: [entry],
          filteredEntries: [entry],
          timePeriod: TimePeriod.week,
          heightCm: null,
        ),
      );
      when(() => weightBloc.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(
        buildSubject(settingsBloc: AppSettingsBloc(), weightBloc: weightBloc),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => weightBloc.add(const SubscribeToWeightChanges())).called(1);
    },
  );

  testWidgets(
    'StatisticsScreen renders metrics from WeightError state with cached entries',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 74.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: now.subtract(const Duration(days: 10)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      final weightBloc = createBloc(
        WeightError(
          errorType: WeightErrorType.readFailed,
          entries: entries,
          filteredEntries: [],
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );

      expect(find.textContaining('74.0'), findsOneWidget);
      expect(find.textContaining('-6.0 kg'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen shows empty state when WeightError has no cached entries',
    (tester) async {
      final settingsBloc = AppSettingsBloc();
      final weightBloc = createBloc(
        const WeightError(
          errorType: WeightErrorType.readFailed,
          entries: [],
          filteredEntries: [],
        ),
      );

      await tester.pumpWidget(
        buildSubject(settingsBloc: settingsBloc, weightBloc: weightBloc),
      );

      expect(find.text('Brak danych do analizy'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen empty state button opens the AddWeightSheet dialog',
    (tester) async {
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

      await tester.tap(find.text('Dodaj pierwszy pomiar'));
      await tester.pumpAndSettle();

      expect(find.byType(AddWeightSheet), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen shows achieved goal badge and progress bar when at target',
    (tester) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 74.0, dateTime: now)];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(75.0));
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
      await tester.pumpAndSettle();

      expect(find.textContaining('Cel osiągnięty'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen shows distance-to-target badge and partial goal progress',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 74.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: now.subtract(const Duration(days: 7)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(70.0));
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
      await tester.pumpAndSettle();

      expect(find.textContaining('4.0 kg do celu'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen shows zero goal progress when moving away from target',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 82.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: now.subtract(const Duration(days: 7)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(75.0));
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
      await tester.pumpAndSettle();

      expect(find.textContaining('7.0 kg do celu'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen treats same start and target weight as fully achieved',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 76.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 75.0,
          dateTime: now.subtract(const Duration(days: 10)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(75.0));
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
      await tester.pumpAndSettle();

      expect(find.textContaining('1.0 kg do celu'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets(
    'StatisticsScreen converts target distance, pace, and change to imperial',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        WeightEntry(id: 2, weightKg: 74.0, dateTime: now),
        WeightEntry(
          id: 1,
          weightKg: 70.0,
          dateTime: now.subtract(const Duration(days: 10)),
        ),
      ];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));
      settingsBloc.add(const TargetWeightChanged(70.0));
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
      await tester.pumpAndSettle();

      expect(find.textContaining('8.8 lb do celu'), findsOneWidget);
      expect(find.textContaining('6.2 lb'), findsOneWidget);
    },
  );

  testWidgets('StatisticsScreen renders achieved badge in dark theme', (
    tester,
  ) async {
    final now = DateTime.now();
    final entries = [WeightEntry(id: 1, weightKg: 74.0, dateTime: now)];

    final settingsBloc = AppSettingsBloc();
    settingsBloc.add(const TargetWeightChanged(75.0));
    final weightBloc = createBloc(
      WeightLoaded(
        entries: entries,
        filteredEntries: entries,
        timePeriod: TimePeriod.week,
        heightCm: null,
      ),
    );

    await tester.pumpWidget(
      buildSubject(
        settingsBloc: settingsBloc,
        weightBloc: weightBloc,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Cel osiągnięty'), findsOneWidget);
  });

  testWidgets(
    'StatisticsScreen renders distance-to-target badge in dark theme',
    (tester) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 74.0, dateTime: now)];

      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(70.0));
      final weightBloc = createBloc(
        WeightLoaded(
          entries: entries,
          filteredEntries: entries,
          timePeriod: TimePeriod.week,
          heightCm: null,
        ),
      );

      await tester.pumpWidget(
        buildSubject(
          settingsBloc: settingsBloc,
          weightBloc: weightBloc,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('do celu'), findsOneWidget);
    },
  );
}
