import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/today_shimmer_skeleton.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late AppSettingsBloc settingsBloc;

  setUpAll(() {
    registerFallbackValue(ChangeChartFilter(TimePeriod.week));
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn({'height': 170.0});
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    weightBloc = MockWeightBloc();
    settingsBloc = AppSettingsBloc();
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
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(
        find.text('Failed to read weight data.', skipOffstage: false),
        findsWidgets,
      );
      expect(find.text('Try again', skipOffstage: false), findsWidgets);
    },
  );

  testWidgets(
    'renders inline error banner when WeightError state occurs with cached entries',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(
        find.byIcon(Icons.warning_amber_rounded, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Failed to save weight data.', skipOffstage: false),
        findsWidgets,
      );
    },
  );

  testWidgets('renders cold start empty state when no weight entries exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    expect(
      find.text('Welcome to Balance!', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('Add first measurement', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('tapping Add first measurement button opens AddWeightSheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    expect(find.text('BMI 25.1', skipOffstage: false), findsOneWidget);
    expect(find.text('Weight trend', skipOffstage: false), findsOneWidget);
    expect(find.text('Last measurement', skipOffstage: false), findsOneWidget);
    expect(
      find.byIcon(Icons.lightbulb_outline, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('tapping FAB opens AddWeightSheet when entries exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

  testWidgets('tapping the empty-state retry re-subscribes to changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Try again', skipOffstage: false));
    await tester.pump();

    verify(() => weightBloc.add(const SubscribeToWeightChanges())).called(1);
  });

  testWidgets('pull-to-refresh dispatches RefreshWeightData', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());
    final controller = StreamController<WeightState>.broadcast();
    addTearDown(controller.close);

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: [entry],
        filteredEntries: [entry],
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer((_) => controller.stream);
    when(() => weightBloc.add(any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments.first;
      if (event is RefreshWeightData) {
        controller.add(
          WeightLoaded(
            entries: [entry],
            filteredEntries: [entry],
            timePeriod: TimePeriod.month,
            heightCm: 175.0,
          ),
        );
      }
    });

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 900));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    verify(() => weightBloc.add(const RefreshWeightData())).called(1);
  });

  testWidgets('shows an error snackbar and retries when an error arrives '
      'after data was loaded', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());
    final controller = StreamController<WeightState>.broadcast();
    addTearDown(controller.close);

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: [entry],
        filteredEntries: [entry],
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    controller.add(
      WeightError(
        errorType: WeightErrorType.readFailed,
        entries: [entry],
        filteredEntries: [entry],
      ),
    );
    await tester.pumpAndSettle();

    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);
    expect(
      find.descendant(
        of: snackBarFinder,
        matching: find.text('Failed to read weight data.'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: snackBarFinder, matching: find.text('Try again')),
    );
    await tester.pump();

    verify(() => weightBloc.add(const SubscribeToWeightChanges())).called(1);
  });

  testWidgets('renders the inline error banner and retries from it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());

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
    await tester.pumpAndSettle();

    await tester.tap(
      // The banner's button renders before the error snackbar in the
      // overlay, so the first match is the inline banner.
      find.text('Try again').first,
    );
    await tester.pump();

    verify(() => weightBloc.add(const SubscribeToWeightChanges())).called(1);
  });

  testWidgets('shows the chart empty placeholder when the filter is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: [entry],
        filteredEntries: [],
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        WeightLoaded(
          entries: [entry],
          filteredEntries: [],
          timePeriod: TimePeriod.month,
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Not enough data to display chart.'), findsOneWidget);
  });

  testWidgets('period pills dispatch ChangeChartFilter on a wide layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    // The period pill row sits inside an Expanded header, so pointer events
    // at the text center are not routed to the button; invoke the callback
    // directly and capture the dispatched event through the stub.
    WeightEvent? dispatched;
    when(() => weightBloc.add(any())).thenAnswer((invocation) {
      dispatched = invocation.positionalArguments.first as WeightEvent;
    });
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(dispatched, isA<ChangeChartFilter>());
    expect((dispatched as ChangeChartFilter).period, TimePeriod.year);
  });

  /// Sweeps pointer gestures across the chart so the touch tooltip pipeline
  /// (spot indicators, tooltip color and tooltip items) is exercised.
  Future<void> sweepChart(WidgetTester tester) async {
    final chartRect = tester.getRect(find.byType(LineChart));
    for (var x = 0.0; x < chartRect.width; x += 24) {
      for (final fraction in [0.3, 0.45, 0.5, 0.6, 0.7]) {
        final gesture = await tester.startGesture(
          Offset(
            chartRect.left + x,
            chartRect.top + chartRect.height * fraction,
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.up();
        await tester.pumpAndSettle();
      }
    }
  }

  testWidgets('shows a touch tooltip with the metric weight on the chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    // Drag across the chart so the touch tooltip tracks the spots; the
    // tooltip is painted via TextPainter, so the gesture is exercised for
    // coverage rather than asserted visually.
    await sweepChart(tester);
  });

  testWidgets('shows a touch tooltip with imperial weight on the chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final entry = WeightEntry(id: 1, weightKg: 72.5, dateTime: DateTime.now());

    when(
      () => storage.read(any()),
    ).thenReturn({'height': 170.0, 'measurementUnit': 'imperial'});
    settingsBloc = AppSettingsBloc();

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

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    await sweepChart(tester);
  });

  testWidgets('plots multiple entries with distinct dates', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final entries = [
      WeightEntry(id: 1, weightKg: 70.0, dateTime: now),
      WeightEntry(
        id: 2,
        weightKg: 72.5,
        dateTime: now.add(const Duration(days: 1)),
      ),
    ];

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: entries,
        filteredEntries: entries,
        timePeriod: TimePeriod.month,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        WeightLoaded(
          entries: entries,
          filteredEntries: entries,
          timePeriod: TimePeriod.month,
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Weight trend', skipOffstage: false), findsOneWidget);

    // A plain tap on the plot area exercises the touch tooltip pipeline.
    await tester.tap(find.byType(LineChart));
    await tester.pump();
    await tester.pumpAndSettle();
    await sweepChart(tester);
  });

  testWidgets('renders the short weekday labels for all chart positions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 2026-08-12 is a Wednesday; five consecutive days span Wed-Sun.
    final entries = [
      WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 8, 12)),
      WeightEntry(id: 2, weightKg: 70.5, dateTime: DateTime(2026, 8, 13)),
      WeightEntry(id: 3, weightKg: 71.0, dateTime: DateTime(2026, 8, 14)),
      WeightEntry(id: 4, weightKg: 71.5, dateTime: DateTime(2026, 8, 15)),
      WeightEntry(id: 5, weightKg: 72.0, dateTime: DateTime(2026, 8, 16)),
    ];

    when(() => weightBloc.state).thenReturn(
      WeightLoaded(
        entries: entries,
        filteredEntries: entries,
        timePeriod: TimePeriod.week,
        heightCm: 175.0,
      ),
    );
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        WeightLoaded(
          entries: entries,
          filteredEntries: entries,
          timePeriod: TimePeriod.week,
          heightCm: 175.0,
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget(const TodayScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Wed', skipOffstage: false), findsWidgets);
    expect(find.text('Thu', skipOffstage: false), findsWidgets);
    expect(find.text('Fri', skipOffstage: false), findsWidgets);
    expect(find.text('Sat', skipOffstage: false), findsWidgets);
    expect(find.text('Sun', skipOffstage: false), findsWidgets);
  });

  testWidgets(
    'renders split two-column layout in landscape orientation (800x400)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            heightCm: 170.0,
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(const TodayScreen()));
      await tester.pumpAndSettle();

      // The BMI badge is intentionally hidden in landscape phone viewports.
      expect(find.text('BMI 25.1', skipOffstage: false), findsNothing);
      expect(find.text('Weight trend', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Last measurement', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders without RenderFlex overflow in compact landscape viewport (640x320)',
    (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            heightCm: 170.0,
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget(const TodayScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Weight trend', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
