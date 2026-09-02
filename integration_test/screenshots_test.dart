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
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';
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
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/settings/presentation/widgets/components/target_weight_sheet.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestones_gallery_sheet.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class FakeWeightRepository implements WeightRepository {
  final List<WeightEntry> entries;
  FakeWeightRepository(this.entries);

  @override
  Stream<List<WeightEntry>> watchAllEntries() => Stream.value(entries);

  @override
  Future<List<WeightEntry>> getAllEntries() async => entries;

  @override
  Future<void> addEntry(WeightEntry entry) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Future<int> bulkImportEntries(List<WeightEntry> entries) async => entries.length;

  @override
  Future<int> syncRemoteEntries(List<WeightEntry> remoteEntries) async => remoteEntries.length;

  @override
  Future<void> clearAllData() async {}
}

List<WeightEntry> generate90MockEntries() {
  final now = DateTime(2026, 9, 2, 8, 0);
  final entries = <WeightEntry>[];
  for (int i = 89; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final base = 92.5 - (92.5 - 87.0) * (89 - i) / 89.0;
    final fluctuation = ((i * 7) % 5 - 2) * 0.1;
    final weight = (i == 0)
        ? 87.0
        : (i == 1)
            ? 87.2
            : double.parse((base + fluctuation).toStringAsFixed(1));
    entries.add(
      WeightEntry(
        id: 90 - i,
        weightKg: weight,
        dateTime: date,
        note: i % 10 == 0 ? 'Morning check' : null,
      ),
    );
  }
  return entries;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockHydratedStorage storage;
  late List<WeightEntry> mockEntries;
  late FakeWeightRepository weightRepo;

  setUpAll(() async {
    await binding.convertFlutterSurfaceToImage();
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    mockEntries = generate90MockEntries();
    weightRepo = FakeWeightRepository(mockEntries);
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
    AppSettingsBloc? settingsBloc,
    WeightBloc? weightBloc,
    PreferredSizeWidget? appBar,
  }) {
    final effectiveSettingsBloc = settingsBloc ?? AppSettingsBloc();
    final effectiveWeightBloc = weightBloc ??
        (WeightBloc(repository: weightRepo)..add(const SubscribeToWeightChanges()));

    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsBloc>.value(value: effectiveSettingsBloc),
        BlocProvider<WeightBloc>.value(value: effectiveWeightBloc),
      ],
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
        // 00_splash (Generated across locales)
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

        // ---------------------------------------------------------------------
        // 02_today / 01_dashboard (Populated with 90 records, 177cm, 87kg, target 85kg)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 02_today/01_dashboard [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges())
              ..add(const ChangeChartFilter(TimePeriod.month));

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const MainNavigationScreen(),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/02_today/01_dashboard_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 02_today / 02_add_measurement (Add/Edit measurement modal sheet)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 02_today/02_add_measurement [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0));
            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: Scaffold(
                    body: SafeArea(
                      child: AddWeightSheet(
                        existingEntry: WeightEntry(
                          id: 90,
                          weightKg: 87.0,
                          dateTime: DateTime(2026, 9, 2, 8, 30),
                          note: 'Morning weigh-in',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/02_today/02_add_measurement_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 02_today / 03_bmi_categories (BMI Categories breakdown dialog)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 02_today/03_bmi_categories [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0));
            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const Scaffold(
                    body: SafeArea(
                      child: BmiLegendDialog(
                        latestWeightKg: 87.0,
                        heightCm: 177.0,
                        currentCategory: BmiCategory.overweight,
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/02_today/03_bmi_categories_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 03_calendar / 01_month_view (Calendar month view with 90 entries & today selected)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 03_calendar/01_month_view [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: CalendarScreen(
                    initialDate: DateTime(2026, 9, 2),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/03_calendar/01_month_view_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 03_calendar / 02_day_details (Calendar view with day empty/no measurements)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 03_calendar/02_day_details [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: CalendarScreen(
                    initialDate: DateTime(2026, 9, 20), // Day without measurements
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/03_calendar/02_day_details_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 04_statistics / 01_overview (Statistics screen with progress & BMI chart)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 04_statistics/01_overview [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges())
              ..add(const ChangeChartFilter(TimePeriod.month));

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const StatisticsScreen(),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/04_statistics/01_overview_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 04_statistics / 02_achievements_gallery (Milestones / Achievements Sheet)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 04_statistics/02_achievements_gallery [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final evaluatedMilestones = MilestoneCalculator.evaluate(
              entries: mockEntries,
              targetWeight: 85.0,
              heightCm: 177.0,
              goalMode: WeightGoalMode.lose,
            );

            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: Scaffold(
                  body: SafeArea(
                    child: MilestonesGallerySheet(
                      milestones: evaluatedMilestones,
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/04_statistics/02_achievements_gallery_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 05_settings / 01_preferences (Main settings screen)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 05_settings/01_preferences [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const SettingsScreen(),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$localeCode/05_settings/01_preferences_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 05_settings / 02_target_weight_sheet (Target weight configuration modal)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 05_settings/02_target_weight_sheet [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            await tester.pumpWidget(
              MultiBlocProvider(
                providers: [
                  BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
                  BlocProvider<WeightBloc>.value(value: weightBloc),
                ],
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const Scaffold(
                    body: SafeArea(
                      child: TargetWeightSheet(
                        currentValueKg: 85.0,
                        measurementUnit: MeasurementUnit.metric,
                        initialGoalMode: WeightGoalMode.lose,
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/05_settings/02_target_weight_sheet_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // ---------------------------------------------------------------------
        // 05_settings / 03_privacy_policy (Privacy Policy Screen)
        // ---------------------------------------------------------------------
        testWidgets(
          'Capture 05_settings/03_privacy_policy [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: const PrivacyPolicyScreen(),
              ),
            );

            await tester.pumpAndSettle();
            await binding.takeScreenshot(
              '$localeCode/05_settings/03_privacy_policy_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
