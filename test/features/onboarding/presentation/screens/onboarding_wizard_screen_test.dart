import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';

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

  /// Advances from step 1 (Welcome) to step 2 (Your Basic Details) to step 3
  /// (CSV Import).
  Future<void> pumpToStep3(WidgetTester tester) async {
    // Advance from Step 1 (Welcome)
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Advance from Step 2 (Your Basic Details)
    await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  /// Skips step 3 (CSV Import) and lands on step 4 (Your Starting Point).
  Future<void> pumpToStep4(WidgetTester tester) async {
    await pumpToStep3(tester);
    await tester.tap(find.byKey(const Key('csv_import_next_button')));
    await tester.pumpAndSettle();
  }

  group('OnboardingWizardScreen Widget Tests', () {
    testWidgets('renders initial welcome screen (step 0) without step text', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Hide step indicator on the Welcome screen.
      expect(find.text('Step 1 of 8'), findsNothing);
      expect(find.text('Welcome to Balance'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('navigates through all 8 steps and completes wizard', (
      tester,
    ) async {
      bool completed = false;
      await tester.pumpWidget(
        buildSubject(onWizardCompleted: () => completed = true),
      );
      await tester.pumpAndSettle();

      // Advance from Step 1 (Welcome)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('Your Basic Details'), findsOneWidget);

      // Advance from Step 2 (Your Basic Details)
      await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 7'), findsOneWidget);
      expect(find.text('Your Past History (Optional)'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Sync height to WeightBloc to prevent heightNotSet errors
      // during initial weight entry.
      verify(
        () => weightBloc.add(any(that: isA<UpdateUserHeight>())),
      ).called(1);

      // Step 3 (CSV Import) -> Skip
      await tester.tap(find.byKey(const Key('csv_import_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 7'), findsOneWidget);
      expect(find.text('Your Starting Point'), findsOneWidget);

      // Step 4 (Your Starting Point) -> Next
      await tester.enterText(
        find.byKey(const Key('initial_weight_input')),
        '75.5',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Log initial weight before wizard completion.
      verify(
        () => weightBloc.add(
          any(
            that: isA<AddWeight>().having((w) => w.weightKg, 'weightKg', 75.5),
          ),
        ),
      ).called(1);

      expect(find.text('Step 4 of 7'), findsOneWidget);
      expect(find.text('Your Dream Goal (Optional)'), findsOneWidget);

      // Step 5 (Target Weight) -> Next (Leave empty for optional target weight)
      await tester.tap(find.text('Next').first);
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 7'), findsOneWidget);
      expect(find.text('Weight Notifications (Optional)'), findsOneWidget);

      // Step 6 (Daily Reminder) -> Next (Skip/Next reminder)
      await tester.tap(find.byKey(const Key('notification_step_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 6 of 7'), findsOneWidget);
      expect(find.text('Health Sync (Optional)'), findsOneWidget);

      // Step 7 (Health Sync) -> Next (skip by not enabling the switch)
      await tester.tap(find.byKey(const Key('health_sync_step_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 7 of 7'), findsOneWidget);
      expect(find.text('Biometric Protection (Optional)'), findsOneWidget);

      // Step 8 (Biometric Protection) -> Next (Skip/Next biometric lock)
      await tester.tap(find.byKey(const Key('biometric_step_next_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(settingsBloc.state.isOnboardingCompleted, isTrue);
    });

    testWidgets('navigates back through steps 4 -> 3 -> 2 via back button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Advance to Step 4 (Your Starting Point)
      await pumpToStep4(tester);

      expect(find.text('Step 3 of 7'), findsOneWidget);
      expect(find.text('Your Starting Point'), findsOneWidget);

      // Back to Step 3 (CSV Import)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 7'), findsOneWidget);
      expect(find.text('Your Past History (Optional)'), findsOneWidget);

      // Back to Step 2 (Your Basic Details)
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 7'), findsOneWidget);
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
        await tester.pumpAndSettle();

        // Advance to Step 3 (CSV Import)
        await pumpToStep3(tester);

        // Step 3 (CSV Import) -> pick file -> continue
        await tester.tap(find.byKey(const Key('csv_import_tile')));
        await tester.pumpAndSettle();
        expect(find.text('Imported 2 entries'), findsOneWidget);

        await tester.tap(find.byKey(const Key('csv_import_continue_button')));
        await tester.pumpAndSettle();

        // Step 4 (Your Starting Point) shows the latest entry pre-filled.
        expect(find.text('Step 3 of 7'), findsOneWidget);
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
        expect(find.text('Step 4 of 7'), findsOneWidget);
      },
    );

    testWidgets('skipping CSV import leaves the initial weight input blank', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Advance to Step 3 (CSV Import)
      await pumpToStep3(tester);

      // Step 3 (CSV Import) -> Skip
      await tester.tap(find.byKey(const Key('csv_import_next_button')));
      await tester.pumpAndSettle();

      // Step 4 (Your Starting Point) starts blank with Next disabled.
      expect(find.text('Step 3 of 7'), findsOneWidget);
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

      // Ensure the welcome text is visible on start
      expect(find.text('Welcome to Balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'shows validation error when height is invalid (e.g. 20 cm) and Next is pressed',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Advance from Step 1 (Welcome)
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        final heightField = find.byKey(const Key('height_cm_input'));
        await tester.enterText(heightField, '20');
        await tester.pumpAndSettle();

        final nextButton = find.widgetWithText(FilledButton, 'Next');
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // Should not navigate to step 3
        expect(find.text('Step 2 of 7'), findsNothing);

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

      expect(find.text('Welcome to Balance'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Your Basic Details'), findsOneWidget);

      // Navigate to step 3 (CSV Import)
      await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 6'), findsOneWidget);
      expect(find.text('Your Past History (Optional)'), findsOneWidget);

      // Skip the optional CSV import and advance to step 4 (Your Starting Point)
      await tester.tap(find.byKey(const Key('csv_import_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 3 of 6'), findsOneWidget);
      expect(find.text('Your Starting Point'), findsOneWidget);

      // Log the initial weight and advance to step 5 (Target Weight)
      await tester.enterText(
        find.byKey(const Key('initial_weight_input')),
        '75.5',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 4 of 6'), findsOneWidget);
      expect(find.text('Your Dream Goal (Optional)'), findsOneWidget);

      // Skip the optional target weight and advance to step 6 (Daily Reminder)
      await tester.tap(find.text('Next').first);
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 6'), findsOneWidget);
      expect(find.text('Weight Notifications (Optional)'), findsOneWidget);

      // Advance from step 6 (Daily Reminder) to step 7 (Health Sync)
      await tester.tap(find.byKey(const Key('notification_step_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 6 of 6'), findsOneWidget);
      expect(find.text('Health Sync (Optional)'), findsOneWidget);

      // Step 7 (Health Sync) is the final step without biometrics: pressing
      // next without enabling the switch finishes the wizard.
      await tester.tap(find.byKey(const Key('health_sync_step_next_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(settingsBloc.state.isOnboardingCompleted, isTrue);
    });
  });
}
