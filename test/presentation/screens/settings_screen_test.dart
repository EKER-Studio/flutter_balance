import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';

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
    when(
      () => weightBloc.state,
    ).thenReturn(const WeightLoaded(entries: [], filteredEntries: []));
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(const WeightLoaded(entries: [], filteredEntries: [])),
    );

    settingsBloc = AppSettingsBloc();
  });

  Widget createTestWidget() {
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
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('renders all section headers', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('APPLICATION'), findsOneWidget);
    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('DATA'), findsOneWidget);
  });

  testWidgets('renders height value from settings', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('170 cm'), findsOneWidget);
  });

  testWidgets('shows theme selection dialog on theme tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('System'));
    await tester.pump();

    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('shows height dialog on height tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('170 cm'));
    await tester.pump();

    expect(find.text('Set Height'), findsOneWidget);
    expect(find.text('Height (cm)'), findsOneWidget);
  });

  testWidgets('shows unit selection dialog on unit tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('Metric (kg, cm)'));
    await tester.pump();

    expect(find.text('Imperial (lb, ft/in)'), findsOneWidget);
  });

  testWidgets('shows target weight dialog on target weight tap', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('Not set'));
    await tester.pump();

    expect(find.text('Target Weight').last, findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
  });

  testWidgets('shows notification switch enabled by default', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    final switchFinder = find.byType(Switch).first;
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
  });

  testWidgets('shows wipe confirmation dialog', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Wipe All Data'), 200);
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    expect(
      find.text(
        'This will permanently delete all your weight entries and reset app settings. This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Wipe Data'), findsOneWidget);
  });
}
