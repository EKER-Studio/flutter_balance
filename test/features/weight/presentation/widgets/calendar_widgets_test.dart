import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/screens/calendar_screen.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_cell.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_empty_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_entries_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_future_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_error_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_month_header.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_shimmer_skeleton.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_weekday_header.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

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

    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.value(<WeightEntry>[]));
  });

  Widget createTestWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsBloc()),
      ],
      child: MaterialApp(
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

    await tester.tap(find.byTooltip('Previous month'));
    expect(prevCalled, isTrue);

    await tester.tap(find.byTooltip('Next month'));
    expect(nextCalled, isTrue);
  });

  testWidgets('CalendarWeekdayHeader renders day indicators', (tester) async {
    await tester.pumpWidget(
      createTestWidget(const CalendarWeekdayHeader()),
    );

    expect(find.byType(CalendarWeekdayHeader), findsOneWidget);
  });

  testWidgets(
      'CalendarDayCell renders day number, selection state, and handles tap', (
    tester,
  ) async {
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
  });

  testWidgets('CalendarDayCell renders star badge when isGoalAchieved is true', (
    tester,
  ) async {
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
  });

  testWidgets('CalendarDayEmptyCard renders empty state UI and add button', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        CalendarDayEmptyCard(selectedDate: DateTime(2026, 7, 15)),
      ),
    );

    expect(find.text('Brak pomiarów w tym dniu'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy), findsOneWidget);
    expect(find.text('Dodaj pomiar'), findsOneWidget);
  });

  testWidgets(
      'CalendarDayFutureCard renders future card and return to today button', (
    tester,
  ) async {
    var todaySelected = false;

    await tester.pumpWidget(
      createTestWidget(
        CalendarDayFutureCard(
          selectedDate: DateTime(2030, 1, 1),
          onSelectToday: () => todaySelected = true,
        ),
      ),
    );

    expect(find.text('Przyszła data'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.text('Przejdź do dzisiaj'), findsOneWidget);

    await tester.tap(find.text('Przejdź do dzisiaj'));
    expect(todaySelected, isTrue);
  });

  testWidgets('CalendarErrorCard renders error message and retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(
        const CalendarErrorCard(errorMessage: 'Database connection failed'),
      ),
    );

    expect(find.text('Błąd odczytu bazy danych'), findsOneWidget);
    expect(find.text('Database connection failed'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);
  });

  testWidgets(
      'CalendarDayEntriesCard displays daily summary stats and goal banner when goal is reached', (
    tester,
  ) async {
    final entries = [
      WeightEntry(id: 1, weightKg: 72.0, dateTime: DateTime(2026, 7, 15, 8, 0)),
      WeightEntry(id: 2, weightKg: 73.0, dateTime: DateTime(2026, 7, 15, 20, 0)),
    ];

    await tester.pumpWidget(
      createTestWidget(
        CalendarDayEntriesCard(
          selectedDate: DateTime(2026, 7, 15),
          entries: entries,
          targetWeight: 72.5,
        ),
      ),
    );

    expect(find.text('Podsumowanie dnia'), findsOneWidget);
    expect(find.textContaining('Cel wagi został osiągnięty'), findsOneWidget);
    expect(find.text('Średnia waga'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);
  });

  testWidgets('CalendarShimmerSkeleton renders pulsing placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const CalendarShimmerSkeleton()),
    );

    expect(find.byType(CalendarShimmerSkeleton), findsOneWidget);
  });

  testWidgets(
      'CalendarScreen renders error card during WeightError state', (
    tester,
  ) async {
    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.error(Exception('Database error')));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppSettingsBloc()),
          BlocProvider(
            create: (context) => WeightBloc(repository: repository)
              ..add(const SubscribeToWeightChanges()),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CalendarErrorCard), findsOneWidget);
  });
}
