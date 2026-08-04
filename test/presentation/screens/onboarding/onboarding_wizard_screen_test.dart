import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/screens/onboarding/onboarding_wizard_screen.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends MockBloc<WeightEvent, WeightState>
    implements WeightBloc {}

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

  Widget buildSubject({VoidCallback? onWizardCompleted}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
        BlocProvider<WeightBloc>.value(value: weightBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingWizardScreen(onWizardCompleted: onWizardCompleted),
      ),
    );
  }

  group('OnboardingWizardScreen Widget Tests', () {
    testWidgets('renders initial Step 1 of 5', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets(
      'navigates through steps 1 -> 2 -> 3 -> 4 -> 5 and completes wizard',
      (tester) async {
        bool completed = false;
        await tester.pumpWidget(
          buildSubject(onWizardCompleted: () => completed = true),
        );

        // Step 1 -> Next
        await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Step 2 of 5'), findsOneWidget);
        expect(find.text('Target Weight'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Height is synced to the weight BLoC so AddWeight in step 5 does not
        // get rejected with a heightNotSet error on a fresh install.
        verify(
          () => weightBloc.add(any(that: isA<UpdateUserHeight>())),
        ).called(1);

        // Step 2 -> Next (Skip target weight)
        await tester.tap(find.text('Skip').first);
        await tester.pumpAndSettle();

        expect(find.text('Step 3 of 5'), findsOneWidget);
        expect(find.text('Daily Reminder'), findsWidgets);

        // Step 3 -> Next (Skip/Next reminder)
        await tester.tap(
          find.byKey(const Key('notification_step_next_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Step 4 of 5'), findsOneWidget);
        expect(find.text('Biometric Lock'), findsWidgets);

        // Step 4 -> Next (Skip/Next biometric lock)
        await tester.tap(find.byKey(const Key('biometric_step_next_button')));
        await tester.pumpAndSettle();

        expect(find.text('Step 5 of 5'), findsOneWidget);
        expect(find.text('Initial Weight'), findsOneWidget);

        // Enter initial weight in Step 5
        await tester.enterText(
          find.byKey(const Key('initial_weight_input')),
          '75.5',
        );
        await tester.tap(find.text('Complete Setup'));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(settingsBloc.state.isOnboardingCompleted, isTrue);

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
      },
    );

    testWidgets('navigates back to Step 1 from Step 2 via back button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      // Advance to Step 2
      await tester.enterText(find.byKey(const Key('height_cm_input')), '170');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 5'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
    });

    testWidgets('renders cleanly in landscape orientation without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disables Next button when height is invalid (e.g. 20 cm)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());

      final heightInput = find.byKey(const Key('height_cm_input'));
      await tester.enterText(heightInput, '20');
      await tester.pump();

      final nextButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets(
      'accessibility audit: height input has text field semantics and focus',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(buildSubject());

        final heightInput = find.byKey(const Key('height_cm_input'));
        await tester.tap(heightInput);
        await tester.pump();

        final semanticsData = tester
            .getSemantics(heightInput)
            .getSemanticsData();
        expect(semanticsData.label, contains('Height'));

        handle.dispose();
      },
    );
  });
}
