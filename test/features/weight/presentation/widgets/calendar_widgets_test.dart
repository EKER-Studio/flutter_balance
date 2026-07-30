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
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_month_header.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_weekday_header.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    repository = MockWeightRepository();
    when(() => repository.watchAllEntries())
        .thenAnswer((_) => Stream.value(<WeightEntry>[]));
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
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

  testWidgets('CalendarDayCell renders day number and handles tap', (
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
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('15'), findsOneWidget);
    await tester.tap(find.text('15'));
    expect(tapped, isTrue);
  });

  testWidgets('CalendarScreen renders month header, weekdays, and grid', (
    tester,
  ) async {
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

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.byType(CalendarMonthHeader), findsOneWidget);
    expect(find.byType(CalendarWeekdayHeader), findsOneWidget);
  });
}
