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
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_empty_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_entries_card.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';

import 'package:balance/features/calendar/presentation/widgets/calendar_error_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_month_header.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_shimmer_skeleton.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_weekday_header.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => Stream.value(<WeightEntry>[]));
  });

  Widget createTestWidget(
    Widget child, {
    AppSettingsBloc? settingsBloc,
    Locale locale = const Locale('pl'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => settingsBloc ?? AppSettingsBloc()),
      ],
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('CalendarMonthHeader triggers month navigation callbacks', (
    tester,
  ) async {
    var prevCalled = false;
    var nextCalled = false;

    await tester.pumpWidget(
      createTestWidget(
        CalendarMonthHeader(
          focusedMonth: DateTime(2026, 7, 1),
          onPreviousMonth: () => prevCalled = true,
          onNextMonth: () => nextCalled = true,
        ),
      ),
    );

    expect(find.textContaining('2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    expect(prevCalled, isTrue);

    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(nextCalled, isTrue);
  });

  testWidgets('CalendarWeekdayHeader renders day indicators', (tester) async {
    await tester.pumpWidget(createTestWidget(const CalendarWeekdayHeader()));

    expect(find.byType(CalendarWeekdayHeader), findsOneWidget);
  });

  testWidgets(
    'CalendarDayCell renders day number, selection state, and handles tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          CalendarDayCell(
            date: DateTime(2026, 7, 15),
            dayNumber: 15,
            entries: const [],
            isToday: false,
            isSelected: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
      await tester.tap(find.text('15'));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'CalendarDayCell renders star badge when isGoalAchieved is true',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CalendarDayCell(
            date: DateTime(2026, 7, 15),
            dayNumber: 15,
            entries: const [],
            isToday: false,
            isSelected: false,
            isGoalAchieved: true,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    },
  );

  testWidgets(
    'CalendarDayEmptyCard renders empty state UI in Polish and English',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CalendarDayEmptyCard(selectedDate: DateTime(2026, 7, 15)),
          locale: const Locale('pl'),
        ),
      );

      expect(find.text('Brak pomiarów w tym dniu'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
      expect(find.text('Dodaj pomiar'), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          CalendarDayEmptyCard(selectedDate: DateTime(2026, 7, 15)),
          locale: const Locale('en'),
        ),
      );

      expect(
        find.text('No measurements recorded for this day'),
        findsOneWidget,
      );
      expect(find.text('Add measurement'), findsOneWidget);
    },
  );

  testWidgets(
    'CalendarErrorCard renders error message and retry button in Polish and English',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CalendarErrorCard(errorMessage: 'Database connection failed'),
          locale: const Locale('pl'),
        ),
      );

      expect(find.text('Błąd odczytu bazy danych'), findsOneWidget);
      expect(find.text('Database connection failed'), findsOneWidget);
      expect(find.text('Spróbuj ponownie'), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          const CalendarErrorCard(errorMessage: 'Database connection failed'),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Database read error'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    },
  );

  testWidgets(
    'CalendarDayEntriesCard displays single entry with note and time',
    (tester) async {
      final entry = WeightEntry(
        id: 1,
        weightKg: 72.5,
        dateTime: DateTime(2026, 7, 15, 8, 30),
        note: 'Morning weight',
      );

      await tester.pumpWidget(
        createTestWidget(
          CalendarDayEntriesCard(
            selectedDate: DateTime(2026, 7, 15),
            entries: [entry],
          ),
        ),
      );

      expect(find.text('72.5 kg'), findsOneWidget);
      expect(find.textContaining('Morning weight'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );

  testWidgets(
    'CalendarDayEntriesCard displays daily summary stats and goal banner when goal is reached',
    (tester) async {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 72.0,
          dateTime: DateTime(2026, 7, 15, 8, 0),
        ),
        WeightEntry(
          id: 2,
          weightKg: 73.0,
          dateTime: DateTime(2026, 7, 15, 20, 0),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          CalendarDayEntriesCard(
            selectedDate: DateTime(2026, 7, 15),
            entries: entries,
            targetWeight: 72.5,
          ),
          locale: const Locale('pl'),
        ),
      );

      expect(find.textContaining('Cel wagi został osiągnięty'), findsOneWidget);
    },
  );

  testWidgets('CalendarDayEntriesCard supports imperial units (lb)', (
    tester,
  ) async {
    final settingsBloc = AppSettingsBloc();
    settingsBloc.emit(
      settingsBloc.state.copyWith(measurementUnit: MeasurementUnit.imperial),
    );

    final entry = WeightEntry(
      id: 1,
      weightKg: 70.0, // ~154.3 lb
      dateTime: DateTime(2026, 7, 15, 8, 30),
    );

    await tester.pumpWidget(
      createTestWidget(
        CalendarDayEntriesCard(
          selectedDate: DateTime(2026, 7, 15),
          entries: [entry],
        ),
        settingsBloc: settingsBloc,
      ),
    );

    expect(find.text('154.3 lb'), findsOneWidget);
  });

  testWidgets('CalendarGrid delegates day cell selection', (tester) async {
    DateTime? selectedDateResult;

    await tester.pumpWidget(
      createTestWidget(
        CalendarGrid(
          focusedMonth: DateTime(2026, 7, 1),
          selectedDate: DateTime(2026, 7, 1),
          entries: const [],
          onDaySelected: (date, _) => selectedDateResult = date,
        ),
      ),
    );

    expect(find.byType(CalendarGrid), findsOneWidget);
    await tester.tap(find.text('15'));
    expect(selectedDateResult, DateTime(2026, 7, 15));
  });

  testWidgets('CalendarShimmerSkeleton renders pulsing placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const CalendarShimmerSkeleton()));

    expect(find.byType(CalendarShimmerSkeleton), findsOneWidget);
  });

  testWidgets(
    'CalendarScreen renders month header, weekdays, grid, and day card in Dark Mode',
    (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AppSettingsBloc()),
            BlocProvider(
              create: (context) =>
                  WeightBloc(repository: repository)
                    ..add(const SubscribeToWeightChanges()),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('pl'),
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: CalendarScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.byType(CalendarMonthHeader), findsOneWidget);
      expect(find.byType(CalendarWeekdayHeader), findsOneWidget);
      expect(find.byType(CalendarDayEmptyCard), findsOneWidget);
    },
  );

  testWidgets('CalendarScreen renders error card during WeightError state', (
    tester,
  ) async {
    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => Stream.error(Exception('Database error')));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppSettingsBloc()),
          BlocProvider(
            create: (context) =>
                WeightBloc(repository: repository)
                  ..add(const SubscribeToWeightChanges()),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CalendarErrorCard), findsOneWidget);
  });
  testWidgets('CalendarDayEntriesCard shows goal banner and dark mode colors', (
    tester,
  ) async {
    final entry = WeightEntry(
      id: 1,
      weightKg: 70.0,
      dateTime: DateTime(2026, 7, 15, 8, 30),
    );

    await tester.pumpWidget(
      createTestWidget(
        CalendarDayEntriesCard(
          selectedDate: DateTime(2026, 7, 15),
          entries: [entry],
          targetWeight: 72.5,
        ),
        themeMode: ThemeMode.dark,
        locale: const Locale('en'),
      ),
    );

    expect(
      find.text('Weight goal was achieved on this day! 🏆'),
      findsOneWidget,
    );
  });

  testWidgets(
    'CalendarDayEntriesCard shows BMI and category when height is set',
    (tester) async {
      final settingsBloc = AppSettingsBloc();
      settingsBloc.emit(settingsBloc.state.copyWith(height: 180.0));

      final entry = WeightEntry(
        id: 1,
        weightKg: 72.5,
        dateTime: DateTime(2026, 7, 15, 8, 30),
      );

      await tester.pumpWidget(
        createTestWidget(
          CalendarDayEntriesCard(
            selectedDate: DateTime(2026, 7, 15),
            entries: [entry],
          ),
          settingsBloc: settingsBloc,
          locale: const Locale('en'),
        ),
      );

      expect(find.text('BMI 22.4'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    },
  );

  testWidgets('CalendarDayEntriesCard add measurement opens the sheet dialog', (
    tester,
  ) async {
    final entry = WeightEntry(
      id: 1,
      weightKg: 72.5,
      dateTime: DateTime(2026, 7, 15, 8, 30),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppSettingsBloc()),
          BlocProvider(create: (context) => WeightBloc(repository: repository)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarDayEntriesCard(
              selectedDate: DateTime(2026, 7, 15),
              entries: [entry],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(AddWeightSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'CalendarDayEntriesCard delete confirms before dispatching DeleteWeight',
    (tester) async {
      final entry = WeightEntry(
        id: 1,
        weightKg: 72.5,
        dateTime: DateTime(2026, 7, 15, 8, 30),
      );
      final weightBloc = WeightBloc(repository: repository);
      addTearDown(weightBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AppSettingsBloc()),
            BlocProvider<WeightBloc>.value(value: weightBloc),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarDayEntriesCard(
                selectedDate: DateTime(2026, 7, 15),
                entries: [entry],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete entry'), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete entry'));
      await tester.pumpAndSettle();

      expect(find.text('Delete entry'), findsNothing);
    },
  );

  testWidgets('CalendarDayEntriesCard delete cancel dispatches nothing', (
    tester,
  ) async {
    final entry = WeightEntry(
      id: 1,
      weightKg: 72.5,
      dateTime: DateTime(2026, 7, 15, 8, 30),
    );
    final weightBloc = WeightBloc(repository: repository);
    addTearDown(weightBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppSettingsBloc()),
          BlocProvider<WeightBloc>.value(value: weightBloc),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarDayEntriesCard(
              selectedDate: DateTime(2026, 7, 15),
              entries: [entry],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete entry'), findsNothing);
  });
}
