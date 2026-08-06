import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/services/csv_import_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/screens/onboarding/onboarding_wizard_screen.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends MockBloc<WeightEvent, WeightState>
    implements WeightBloc {}

/// Test double for [CsvImportService] that returns a canned result.
class FakeCsvImportService extends CsvImportService {
  FakeCsvImportService(this.result);

  final CsvImportResult? result;

  int calls = 0;

  @override
  Future<CsvImportResult?> pickAndImport() async {
    calls++;
    return result;
  }
}

void main() {
  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;
  late MockWeightBloc weightBloc;

  setUpAll(() {
    registerFallbackValue(const AddWeight(weightKg: 70.0));
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    settingsBloc = AppSettingsBloc();
    weightBloc = MockWeightBloc();
    when(() => weightBloc.state).thenReturn(
      const WeightLoaded(
        entries: [],
        filteredEntries: [],
        timePeriod: TimePeriod.month,
        heightCm: 170.0,
      ),
    );
  });

  tearDown(() {
    settingsBloc.close();
  });

  Widget buildSubject({
    VoidCallback? onWizardCompleted,
    CsvImportService? csvImportService,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
        BlocProvider<WeightBloc>.value(value: weightBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingWizardScreen(
          onWizardCompleted: onWizardCompleted,
          csvImportService: csvImportService,
        ),
      ),
    );
  }

  /// Advances from step 1 (Units & Height) to step 2 (CSV Import).
  Future<void> pumpToStep2(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  /// Skips step 2 (CSV Import) and lands on step 3 (Initial Weight).
  Future<void> pumpToStep3(WidgetTester tester) async {
    await pumpToStep2(tester);
    await tester.tap(find.byKey(const Key('csv_import_skip_button')));
    await tester.pumpAndSettle();
  }

  group('OnboardingWizardScreen Widget Tests', () {
    testWidgets('renders initial Step 1 of 6', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets(
      'navigates through steps 1 -> 2 -> 3 -> 4 -> 5 -> 6 and completes wizard',
      (tester) async {
        bool completed = false;
        await tester.pumpWidget(
          buildSubject(onWizardCompleted: () => completed = true),
        );

        // Step 1 (Units & Height) -> Next
        await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Step 2 of 6'), findsOneWidget);
        expect(find.text('Import existing history?'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Height is synced to the weight BLoC so AddWeight in step 3 does not
        // get rejected with a heightNotSet error on a fresh install.
        verify(
          () => weightBloc.add(any(that: isA<UpdateUserHeight>())),
        ).called(1);

        // Step 2 (CSV Import) -> Skip
        await tester.tap(find.byKey(const Key('csv_import_skip_button')));
        await tester.pumpAndSettle();

        expect(find.text('Step 3 of 6'), findsOneWidget);
        expect(find.text('Initial Weight'), findsOneWidget);

        // Step 3 (Initial Weight) -> Next
        await tester.enterText(
          find.byKey(const Key('initial_weight_input')),
          '75.5',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Initial weight is logged before the wizard completes.
        verify(
          () => weightBloc.add(
            any(
              that: isA<AddWeight>().having(
                (w) => w.weightKg,
                'weightKg',
                75.5,
              ),
            ),
          ),
        ).called(1);

        expect(find.text('Step 4 of 6'), findsOneWidget);
        expect(find.text('Target Weight (Optional)'), findsOneWidget);

        // Step 4 (Target Weight) -> Next (Leave empty for optional target weight)
        await tester.tap(find.text('Next').first);
        await tester.pumpAndSettle();

        expect(find.text('Step 5 of 6'), findsOneWidget);
        expect(find.text('Daily Reminder (Optional)'), findsOneWidget);

        // Step 5 (Daily Reminder) -> Next (Skip/Next reminder)
        await tester.tap(
          find.byKey(const Key('notification_step_next_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Step 6 of 6'), findsOneWidget);
        expect(find.text('Biometric Lock (Optional)'), findsOneWidget);

        // Step 6 (Biometric Lock) -> Next (Skip/Next biometric lock)
        await tester.tap(find.byKey(const Key('biometric_step_next_button')));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(settingsBloc.state.isOnboardingCompleted, isTrue);
      },
    );

    testWidgets('navigates back through steps 3 -> 2 -> 1 via back button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      // Advance to Step 3 (Initial Weight)
      await pumpToStep3(tester);

      expect(find.text('Step 3 of 6'), findsOneWidget);
      expect(find.text('Initial Weight'), findsOneWidget);

      // Back to Step 2 (CSV Import)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 6'), findsOneWidget);
      expect(find.text('Import existing history?'), findsOneWidget);

      // Back to Step 1 (Units & Height)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets(
      'pre-fills initial weight with the latest imported CSV entry and logs '
      'it on Next',
      (tester) async {
        final service = FakeCsvImportService((
          entries: [
            WeightEntry(weightKg: 75.2, dateTime: DateTime(2024, 1, 15)),
            WeightEntry(weightKg: 86.0, dateTime: DateTime(2024, 1, 16)),
          ],
          skippedRows: 0,
        ));

        await tester.pumpWidget(buildSubject(csvImportService: service));

        // Step 1 (Units & Height) -> Next
        await pumpToStep2(tester);

        // Step 2 (CSV Import) -> pick file -> continue
        await tester.tap(find.byKey(const Key('csv_import_pick_button')));
        await tester.pumpAndSettle();
        expect(find.text('Imported 2 measurements!'), findsOneWidget);

        await tester.tap(find.byKey(const Key('csv_import_continue_button')));
        await tester.pumpAndSettle();

        // Step 3 (Initial Weight) shows the latest entry pre-filled.
        expect(find.text('Step 3 of 6'), findsOneWidget);
        final field = tester.widget<TextField>(
          find.byKey(const Key('initial_weight_input')),
        );
        expect(field.controller!.text, '86.0');

        // Confirm without editing logs the pre-filled weight.
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        verify(
          () => weightBloc.add(
            any(
              that: isA<AddWeight>().having(
                (w) => w.weightKg,
                'weightKg',
                86.0,
              ),
            ),
          ),
        ).called(1);
        expect(find.text('Step 4 of 6'), findsOneWidget);
      },
    );

    testWidgets('skipping CSV import leaves the initial weight input blank', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      // Step 1 (Units & Height) -> Next
      await pumpToStep2(tester);

      // Step 2 (CSV Import) -> Skip
      await tester.tap(find.byKey(const Key('csv_import_skip_button')));
      await tester.pumpAndSettle();

      // Step 3 (Initial Weight) starts blank with Next disabled.
      expect(find.text('Step 3 of 6'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('initial_weight_input')),
      );
      expect(field.controller!.text, isEmpty);

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('renders cleanly in landscape orientation without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'shows validation error when height is invalid (e.g. 20 cm) and Next is pressed',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        final heightField = find.byKey(const Key('height_cm_input'));
        await tester.enterText(heightField, '20');
        await tester.pumpAndSettle();

        final nextButton = find.widgetWithText(FilledButton, 'Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // Should not navigate to step 2
        expect(find.text('Step 2 of 6'), findsNothing);

        // Should display the validation error text
        expect(
          find.text('Height must be between 50 and 250 cm'),
          findsOneWidget,
        );
      },
    );

    testWidgets('skips Biometric step if device does not support it', (
      tester,
    ) async {
      settingsBloc.add(const UpdateBiometricSupport(false));

      bool completed = false;
      await tester.pumpWidget(
        buildSubject(onWizardCompleted: () => completed = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);

      // Navigate to step 2 (CSV Import)
      await pumpToStep2(tester);

      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('Import existing history?'), findsOneWidget);

      // Skip the optional CSV import and advance to step 3 (Initial Weight)
      await tester.tap(find.byKey(const Key('csv_import_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('Initial Weight'), findsOneWidget);

      // Log the initial weight and advance to step 4 (Target Weight)
      await tester.enterText(
        find.byKey(const Key('initial_weight_input')),
        '75.5',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('Target Weight (Optional)'), findsOneWidget);

      // Skip the optional target weight and advance to step 5 (Daily Reminder)
      await tester.tap(find.text('Next').first);
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Daily Reminder (Optional)'), findsOneWidget);

      // Step 5 is the final step without biometrics: completing it finishes
      // the wizard (no further navigation).
      await tester.tap(find.byKey(const Key('notification_step_next_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(settingsBloc.state.isOnboardingCompleted, isTrue);
    });
  });
}
