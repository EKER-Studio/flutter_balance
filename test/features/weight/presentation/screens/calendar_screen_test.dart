import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/time_period.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/screens/calendar_screen.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
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
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  WeightBloc createBloc(WeightState state) {
    final bloc = WeightBloc(repository: repository);
    bloc.emit(state);
    return bloc;
  }

  Widget buildSubject(WeightState state) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppSettingsBloc()),
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
  });
}

String _monthName(DateTime date) {
  const months = [
    'styczeń',
    'luty',
    'marzec',
    'kwiecień',
    'maj',
    'czerwiec',
    'lipiec',
    'sierpień',
    'wrzesień',
    'październik',
    'listopad',
    'grudzień',
  ];
  return months[date.month - 1];
}
