import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/time_period.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/screens/today_screen.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

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
    settingsBloc = AppSettingsBloc()..add(const UpdateHeight(170.0));
  });

  Widget createTestWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeightBloc>.value(value: weightBloc),
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('renders shimmer skeleton during WeightLoading state', (
    tester,
  ) async {
    when(() => weightBloc.state).thenReturn(const WeightLoading());
    when(
      () => weightBloc.stream,
    ).thenAnswer((_) => Stream.value(const WeightLoading()));

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pump();

    expect(find.byType(TodayShimmerSkeleton), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets(
    'renders error card with retry button during WeightError state with empty entries',
    (tester) async {
      when(() => weightBloc.state).thenReturn(
        const WeightError(
          errorType: WeightErrorType.readFailed,
          entries: [],
          filteredEntries: [],
        ),
      );
      when(() => weightBloc.stream).thenAnswer(
        (_) => Stream.value(
          const WeightError(
            errorType: WeightErrorType.readFailed,
            entries: [],
            filteredEntries: [],
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(const TodayScreen()));
      await tester.pump();

      expect(find.text('Failed to read weight data.'), findsWidgets);
      expect(find.text('Try again'), findsWidgets);
    },
  );

  testWidgets(
    'renders inline error banner when WeightError state occurs with cached entries',
    (tester) async {
      final entry = WeightEntry(
        id: 1,
        weightKg: 70.0,
        dateTime: DateTime.now(),
      );

      when(() => weightBloc.state).thenReturn(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          entries: [entry],
          filteredEntries: [entry],
        ),
      );
      when(() => weightBloc.stream).thenAnswer(
        (_) => Stream.value(
          WeightError(
            errorType: WeightErrorType.writeFailed,
            entries: [entry],
            filteredEntries: [entry],
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(const TodayScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Failed to save weight data.'), findsWidgets);
    },
  );

  testWidgets('renders cold start empty state when no weight entries exist', (
    tester,
  ) async {
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
          heightCm: 170.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pump();

    expect(find.text('Welcome to PureWeight!'), findsOneWidget);
    expect(find.text('Add first measurement'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('tapping Add first measurement button opens AddWeightSheet', (
    tester,
  ) async {
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
          heightCm: 170.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add first measurement'));
    await tester.pumpAndSettle();

    expect(find.byType(AddWeightSheet), findsOneWidget);
  });

  testWidgets('renders cards and FAB when weight entries exist', (
    tester,
  ) async {
    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());

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
          heightCm: 170.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    expect(find.text('25.1 BMI'), findsOneWidget);
    expect(find.text('Weight trend'), findsOneWidget);
    expect(find.text('Last measurement'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tapping FAB opens AddWeightSheet when entries exist', (
    tester,
  ) async {
    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());

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
          heightCm: 170.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddWeightSheet), findsOneWidget);
  });
}
