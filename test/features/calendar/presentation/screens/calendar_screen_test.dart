import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_error_card.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';

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

  Widget buildSubject(WeightState state, {AppSettingsBloc? settingsBloc}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settingsBloc ?? AppSettingsBloc()),
        BlocProvider.value(value: createBloc(state)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('pl'),
        home: CalendarScreen(),
      ),
    );
  }

  group('CalendarScreen Tests', () {
    testWidgets('CalendarScreen renders month grid and empty day card', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          const WeightLoaded(
            entries: [],
            filteredEntries: [],
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
        ),
      );

      expect(find.text('Kalendarz'), findsOneWidget);
      expect(find.text('Brak pomiarów w tym dniu'), findsOneWidget);
      expect(find.text('Dodaj pomiar'), findsOneWidget);
    });

    testWidgets('CalendarScreen shows entries card for the selected day', (
      tester,
    ) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 72.5, dateTime: now)];

      await tester.pumpWidget(
        buildSubject(
          WeightLoaded(
            entries: entries,
            filteredEntries: entries,
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
        ),
      );

      expect(find.text('72.5 kg'), findsOneWidget);
      expect(find.text('Dodaj kolejny pomiar'), findsOneWidget);
    });

    testWidgets('CalendarScreen navigates between months', (tester) async {
      final now = DateTime.now();
      final currentMonthName = _monthName(now);
      final previousMonthDate = DateTime(now.year, now.month - 1, 1);

      await tester.pumpWidget(
        buildSubject(
          const WeightLoaded(
            entries: [],
            filteredEntries: [],
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
        ),
      );

      expect(find.textContaining(currentMonthName), findsWidgets);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.textContaining(_monthName(previousMonthDate)), findsWidgets);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.textContaining(currentMonthName), findsWidgets);
    });

    testWidgets(
      'CalendarScreen opens day detail sheet when tapping a day with entries',
      (tester) async {
        final now = DateTime.now();
        final entries = [WeightEntry(id: 1, weightKg: 68.2, dateTime: now)];

        await tester.pumpWidget(
          buildSubject(
            WeightLoaded(
              entries: entries,
              filteredEntries: entries,
              timePeriod: TimePeriod.week,
              heightCm: null,
            ),
          ),
        );

        await tester.tap(find.text('${now.day}').first);
        await tester.pumpAndSettle();

        expect(find.text('68.2 kg'), findsWidgets);
      },
    );

    testWidgets(
      'CalendarScreen inline Add button opens AddWeightSheet dialog',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            const WeightLoaded(
              entries: [],
              filteredEntries: [],
              timePeriod: TimePeriod.month,
              heightCm: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.dragUntilVisible(
          find.byIcon(Icons.add),
          find.byType(SingleChildScrollView),
          const Offset(0, -50),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(AddWeightSheet), findsOneWidget);
      },
    );

    testWidgets('CalendarScreen renders error card for WeightError state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          const WeightError(
            errorType: WeightErrorType.readFailed,
            entries: [],
            filteredEntries: [],
          ),
        ),
      );

      expect(find.byType(CalendarErrorCard), findsOneWidget);
    });

    testWidgets('CalendarScreen renders when constructed non-const', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: AppSettingsBloc()),
            BlocProvider.value(
              value: createBloc(
                const WeightLoaded(
                  entries: [],
                  filteredEntries: [],
                  timePeriod: TimePeriod.week,
                  heightCm: null,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pl'),
            home: CalendarScreen(key: const ValueKey('non_const_calendar')),
          ),
        ),
      );

      expect(find.text('Kalendarz'), findsOneWidget);
    });

    testWidgets('marks the entry day as goal achieved when the weight is at '
        'or below the target', (tester) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 60.0, dateTime: now)];
      final settingsBloc = AppSettingsBloc();
      settingsBloc.add(const TargetWeightChanged(65));

      await tester.pumpWidget(
        buildSubject(
          WeightLoaded(
            entries: entries,
            filteredEntries: entries,
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
          settingsBloc: settingsBloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows indicator dots on a non-selected day with entries', (
      tester,
    ) async {
      final now = DateTime.now();
      final otherDay = now.day > 1
          ? DateTime(now.year, now.month, now.day - 1)
          : DateTime(now.year, now.month, now.day + 1);
      final entries = [WeightEntry(id: 1, weightKg: 70.0, dateTime: otherDay)];

      await tester.pumpWidget(
        buildSubject(
          WeightLoaded(
            entries: entries,
            filteredEntries: entries,
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
        ),
      );

      // The entry day (not selected) renders one 4x4 indicator dot.
      final dot = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minWidth == 4 &&
            widget.constraints?.maxWidth == 4 &&
            widget.constraints?.minHeight == 4 &&
            widget.constraints?.maxHeight == 4,
      );
      expect(dot, findsWidgets);
    });

    testWidgets('tapping an entry card is a safe no-op', (tester) async {
      final now = DateTime.now();
      final entries = [WeightEntry(id: 1, weightKg: 70.5, dateTime: now)];

      await tester.pumpWidget(
        buildSubject(
          WeightLoaded(
            entries: entries,
            filteredEntries: entries,
            timePeriod: TimePeriod.week,
            heightCm: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('70.5 kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('70.5 kg'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'CalendarScreen shows average for multiple entries on the selected day',
      (tester) async {
        final now = DateTime.now();
        final entries = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: now),
          WeightEntry(id: 2, weightKg: 80.0, dateTime: now),
        ];

        await tester.pumpWidget(
          buildSubject(
            WeightLoaded(
              entries: entries,
              filteredEntries: entries,
              timePeriod: TimePeriod.week,
              heightCm: null,
            ),
          ),
        );

        expect(find.text('2 pomiary • Średnia waga: 75.0 kg'), findsOneWidget);
      },
    );

    testWidgets(
      'CalendarScreen shows imperial average for multiple entries on the selected day',
      (tester) async {
        final now = DateTime.now();
        final entries = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: now),
          WeightEntry(id: 2, weightKg: 80.0, dateTime: now),
        ];

        final settingsBloc = AppSettingsBloc();
        settingsBloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial));

        await tester.pumpWidget(
          buildSubject(
            WeightLoaded(
              entries: entries,
              filteredEntries: entries,
              timePeriod: TimePeriod.week,
              heightCm: null,
            ),
            settingsBloc: settingsBloc,
          ),
        );

        expect(find.text('2 pomiary • Średnia waga: 165.3 lb'), findsOneWidget);
      },
    );
  });
}

String _monthName(DateTime date) {
  const months = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];
  return months[date.month - 1];
}
