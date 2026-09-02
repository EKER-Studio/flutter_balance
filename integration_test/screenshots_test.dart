@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/csv_import_success_view.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_app_bar.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_biometric_lock.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_health_sync.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_reminder_notification.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_target_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_welcome.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  setUp(() {
    settingsBloc = AppSettingsBloc();
  });

  // All 10 officially supported target locales
  const supportedLocales = <String>[
    'en',
    'de',
    'ja',
    'fr',
    'es',
    'pl',
    'pt',
    'nl',
    'it',
    'ko',
  ];

  Widget buildAppWrapper({
    required Widget child,
    required Locale locale,
    required ThemeData theme,
    required ThemeMode themeMode,
    PreferredSizeWidget? appBar,
  }) {
    return BlocProvider<AppSettingsBloc>.value(
      value: settingsBloc,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: theme,
        themeMode: themeMode,
        home: Scaffold(
          appBar: appBar,
          body: SafeArea(child: child),
        ),
      ),
    );
  }

  group('Automated Multi-Locale Screenshots Generator', () {
    for (final localeCode in supportedLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // ---------------------------------------------------------------------
        // 00_splash (Generated in en/ and across locales)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 00_splash [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                child: const AppSplashScreen(),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/00_splash/splash_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 01_welcome
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/01_welcome [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                child: StepWelcome(onNext: () {}),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/01_welcome_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 02_units_height (177 cm)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/02_units_height [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 1,
                  displayTotalSteps: 7,
                  progress: 1 / 7,
                  onBackPressed: () {},
                ),
                child: StepUnitsHeight(
                  initialUnit: MeasurementUnit.metric,
                  initialHeightCm: 177.0,
                  isCurrentPage: true,
                  onNext: (_, _) {},
                ),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/02_units_height_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 03_csv_import (90 records loaded)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/03_csv_import [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 2,
                  displayTotalSteps: 7,
                  progress: 2 / 7,
                  onBackPressed: () {},
                ),
                child: CsvImportSuccessView(
                  count: 90,
                  onContinue: () {},
                  isLandscape: false,
                ),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/03_csv_import_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 04_starting_point (87.0 kg)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/04_starting_point [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 3,
                  displayTotalSteps: 7,
                  progress: 3 / 7,
                  onBackPressed: () {},
                ),
                child: StepInitialWeight(
                  unit: MeasurementUnit.metric,
                  initialWeightKg: 87.0,
                  initialTimestamp: DateTime(2026, 9, 2, 8, 0),
                  onNext: (_, _) {},
                ),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/04_starting_point_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 05_target_weight (85.0 kg, goal: lose 2.0 kg)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/05_target_weight [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 4,
                  displayTotalSteps: 7,
                  progress: 4 / 7,
                  onBackPressed: () {},
                ),
                child: StepTargetWeight(
                  unit: MeasurementUnit.metric,
                  initialWeightKg: 87.0,
                  initialTargetWeightKg: 85.0,
                  initialGoalMode: WeightGoalMode.lose,
                  onNext: (_, _) {},
                ),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/05_target_weight_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 06_notifications
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/06_notifications [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 5,
                  displayTotalSteps: 7,
                  progress: 5 / 7,
                  onBackPressed: () {},
                ),
                child: StepReminderNotification(onNext: () {}),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/06_notifications_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 07_health_sync
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/07_health_sync [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 6,
                  displayTotalSteps: 7,
                  progress: 6 / 7,
                  onBackPressed: () {},
                ),
                child: StepHealthSync(onNext: () {}),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/07_health_sync_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 01_onboarding / 08_biometric_lock
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 01_onboarding/08_biometric_lock [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 7,
                  displayTotalSteps: 7,
                  progress: 1.0,
                  onBackPressed: () {},
                ),
                child: StepBiometricLock(onNext: () {}),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/01_onboarding/08_biometric_lock_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
