import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_status_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/hero_progress_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/weight_range_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/statistics_content_section.dart';

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

      final rangeCard = find.byType(WeightRangeCard);
      expect(
        find.descendant(of: rangeCard, matching: find.textContaining('74.0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rangeCard, matching: find.textContaining('80.0')),
        findsOneWidget,
      );

      final heroCard = find.byType(HeroProgressCard);
      expect(
        find.descendant(of: heroCard, matching: find.text('-6.0')),
        findsOneWidget,
      );
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

    expect(find.text('3 dni'), findsNWidgets(2));
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

      expect(find.text('2 dni'), findsNWidgets(2));
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

    expect(find.text('1 dzień'), findsNWidgets(2));
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
      expect(find.byType(BmiStatusCard), findsOneWidget);
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

      final rangeCard = find.byType(WeightRangeCard);
      expect(
        find.descendant(of: rangeCard, matching: find.textContaining('74.0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rangeCard, matching: find.textContaining('80.0')),
        findsOneWidget,
      );

      final heroCard = find.byType(HeroProgressCard);
      expect(
        find.descendant(of: heroCard, matching: find.text('-6.0')),
        findsOneWidget,
      );
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

  testWidgets(
    'StatisticsScreen renders single column clamped to 480 on mobile landscape',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      await tester.pumpAndSettle();

      final clampedLayoutFinder = find.byType(ClampedLayout);
      expect(clampedLayoutFinder, findsOneWidget);
      final clampedLayout = tester.widget<ClampedLayout>(clampedLayoutFinder);
      expect(clampedLayout.maxWidth, 480);
    },
  );

  testWidgets(
    'StatisticsScreen renders multi-column layout on tablet landscape',
    (tester) async {
      tester.view.physicalSize = const Size(960, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settingsBloc = AppSettingsBloc();
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 75.0, dateTime: now)];
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

      final clampedLayoutFinder = find.byType(ClampedLayout);
      expect(clampedLayoutFinder, findsOneWidget);
      final clampedLayout = tester.widget<ClampedLayout>(clampedLayoutFinder);
      expect(clampedLayout.maxWidth, 1200);
    },
  );

  group('Custom Weekly Pace Window Tests', () {
    test('calculateWeeklyPace returns null for less than 2 entries', () {
      expect(StatisticsContentSection.calculateWeeklyPace([]), isNull);
      expect(
        StatisticsContentSection.calculateWeeklyPace([
          WeightEntry(id: 1, weightKg: 80, dateTime: DateTime(2026, 8, 1)),
        ]),
        isNull,
      );
    });

    test('calculateWeeklyPace filters entries based on custom windowDays', () {
      final now = DateTime(2026, 8, 30);
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 80,
          dateTime: DateTime(2026, 8, 1),
        ), // 29 days ago
        WeightEntry(
          id: 2,
          weightKg: 78,
          dateTime: DateTime(2026, 8, 18),
        ), // 12 days ago
        WeightEntry(
          id: 3,
          weightKg: 77,
          dateTime: DateTime(2026, 8, 28),
        ), // 2 days ago
      ];

      // 7-day window: only entry 3 is within last 7 days -> returns null
      expect(
        StatisticsContentSection.calculateWeeklyPace(
          entries,
          windowDays: 7,
          now: now,
        ),
        isNull,
      );

      // 14-day window: entry 2 (78kg) and entry 3 (77kg), difference is -1kg over 10 days (10/7 weeks = 1.428 weeks)
      // pace = -1 / (10/7) = -0.7 kg/week
      final pace14 = StatisticsContentSection.calculateWeeklyPace(
        entries,
        windowDays: 14,
        now: now,
      );
      expect(pace14, closeTo(-0.7, 0.05));

      // 30-day window: includes all 3 entries (80kg -> 77kg over 27 days = 3.857 weeks)
      // pace = -3 / (27/7) = -0.777 kg/week
      final pace30 = StatisticsContentSection.calculateWeeklyPace(
        entries,
        windowDays: 30,
        now: now,
      );
      expect(pace30, closeTo(-0.78, 0.05));
    });
  });

  group('StatisticsScreen Share Action', () {
    testWidgets('renders share button in AppTopBar when entries exist', (
      tester,
    ) async {
      final entries = [
        WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime.now()),
      ];
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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('hides share button in AppTopBar when entries list is empty', (
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
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_outlined), findsNothing);
    });
  });
}
