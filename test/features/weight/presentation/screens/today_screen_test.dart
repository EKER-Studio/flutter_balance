import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/screens/today_screen.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    weightBloc = MockWeightBloc();
    settingsBloc = AppSettingsBloc();
  });

  testWidgets('renders cold start empty state when no weight entries exist', (tester) async {
    when(() => weightBloc.state).thenReturn(
      const WeightLoaded(
        entries: [],
        filteredEntries: [],
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        const WeightLoaded(
          entries: [],
          filteredEntries: [],
          timePeriod: TimePeriod.month,
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WeightBloc>.value(value: weightBloc),
          BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TodayScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Welcome to PureWeight!'), findsOneWidget);
    expect(find.text('Add first measurement'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('renders cards and FAB when weight entries exist', (tester) async {
    final entry = WeightEntry(
      id: 1,
      weightKg: 72.5,
      dateTime: DateTime.now(),
    );

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: [entry],
        filteredEntries: [entry],
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        WeightLoaded(
          entries: [entry],
          filteredEntries: [entry],
          timePeriod: TimePeriod.month,
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WeightBloc>.value(value: weightBloc),
          BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TodayScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('BMI'), findsOneWidget);
    expect(find.text('Weight trend'), findsOneWidget);
    expect(find.text('Latest measurement'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
