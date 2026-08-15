import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late AppSettingsBloc settingsBloc;

  setUpAll(() {
    registerFallbackValue(const AddWeight(weightKg: 70.0));
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    weightBloc = MockWeightBloc();
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
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders date, time, weight, and note fields', (tester) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    expect(find.text('Measurement date'), findsOneWidget);
    expect(find.text('Measurement time'), findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
    expect(find.text('Note (optional)'), findsOneWidget);
  });

  testWidgets('parses comma as decimal separator and dispatches AddWeight', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, '72,5');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(
      () => weightBloc.add(
        any(
          that: isA<AddWeight>().having(
            (e) => e.weightKg,
            'weightKg',
            closeTo(72.5, 0.01),
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('parses dot as decimal separator and dispatches AddWeight', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, '72.5');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(
      () => weightBloc.add(
        any(
          that: isA<AddWeight>().having(
            (e) => e.weightKg,
            'weightKg',
            closeTo(72.5, 0.01),
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('prevents saving when dateTime is in the future', (tester) async {
    final futureDate = DateTime.now().add(const Duration(days: 10));

    await tester.pumpWidget(
      createTestWidget(AddWeightSheet(initialDate: futureDate)),
    );
    await tester.pumpAndSettle();

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, '72.5');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Date and time cannot be in the future'), findsOneWidget);
    verifyNever(() => weightBloc.add(any()));
  });

  testWidgets('cancel dismisses the sheet without dispatching', (tester) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AddWeightSheet), findsNothing);
    verifyNever(() => weightBloc.add(any()));
  });

  testWidgets('choosing a date through the picker updates the field', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('dismissing the date picker leaves the field unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('choosing a time through the picker updates the field', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.access_time_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('shows validation errors for empty and non-numeric weights', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Weight cannot be empty'), findsOneWidget);

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, 'abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid number'), findsOneWidget);

    await tester.enterText(weightField, '301');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Weight must be between 20 and 300 kg'), findsOneWidget);
    verifyNever(() => weightBloc.add(any()));
  });

  testWidgets('dispatches AddWeight with a note when one is entered', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, '72.5');
    final noteField = find.byType(TextFormField).at(1);
    await tester.enterText(noteField, 'morning');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => weightBloc.add(
        any(that: isA<AddWeight>().having((e) => e.note, 'note', 'morning')),
      ),
    ).called(1);
  });

  testWidgets('uses the imperial unit for validation and conversion', (
    tester,
  ) async {
    when(() => storage.read(any())).thenReturn({'measurementUnit': 'imperial'});
    settingsBloc = AppSettingsBloc();

    await tester.pumpWidget(createTestWidget(const AddWeightSheet()));
    await tester.pumpAndSettle();

    expect(find.text('Weight in lb'), findsOneWidget);

    final weightField = find.byType(TextFormField).at(0);
    await tester.enterText(weightField, '160');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(
      () => weightBloc.add(
        any(
          that: isA<AddWeight>().having(
            (e) => e.weightKg,
            'weightKg',
            closeTo(72.57, 0.01),
          ),
        ),
      ),
    ).called(1);
  });
}
