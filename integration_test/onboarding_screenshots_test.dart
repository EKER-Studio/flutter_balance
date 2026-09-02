@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/models/measurement_unit.dart';
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
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();
  late FakeWeightRepository weightRepo;

  setUpAll(() async {
    weightRepo = await initScreenshotEnvironment(binding);
  });

  group('01_onboarding Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 01_onboarding / 01_welcome
        testWidgets(
          'Capture 01_onboarding/01_welcome [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                child: StepWelcome(onNext: () {}),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/01_welcome_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 02_units_height (177 cm)
        testWidgets(
          'Capture 01_onboarding/02_units_height [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/02_units_height_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 03_csv_import (90 records loaded)
        testWidgets(
          'Capture 01_onboarding/03_csv_import [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/03_csv_import_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 04_starting_point (87.0 kg)
        testWidgets(
          'Capture 01_onboarding/04_starting_point [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
                appBar: OnboardingAppBar(
                  displayStep: 3,
                  displayTotalSteps: 7,
                  progress: 3 / 7,
                  onBackPressed: () {},
                ),
                child: StepInitialWeight(
                  unit: MeasurementUnit.metric,
                  initialWeightKg: 87.0,
                  initialTimestamp: DateTime(2026, 9, 2, 9, 41),
                  onNext: (_, _) {},
                ),
                locale: locale,
                theme: theme,
                themeMode: themeMode,
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/04_starting_point_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 05_target_weight (85.0 kg, goal: lose 2.0 kg)
        testWidgets(
          'Capture 01_onboarding/05_target_weight [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/05_target_weight_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 06_notifications
        testWidgets(
          'Capture 01_onboarding/06_notifications [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/06_notifications_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 07_health_sync
        testWidgets(
          'Capture 01_onboarding/07_health_sync [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/07_health_sync_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 01_onboarding / 08_biometric_lock
        testWidgets(
          'Capture 01_onboarding/08_biometric_lock [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              buildScreenshotAppWrapper(
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
                weightRepo: weightRepo,
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$prefix$localeCode/01_onboarding/08_biometric_lock_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
