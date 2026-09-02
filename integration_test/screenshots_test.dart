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
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
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
  Future<int> bulkImportEntries(List<WeightEntry> entries) async =>
      entries.length;

  @override
  Future<int> syncRemoteEntries(List<WeightEntry> remoteEntries) async =>
      remoteEntries.length;

  @override
  Future<void> clearAllData() async {}
}

List<WeightEntry> generate90MockEntries() {
  final now = DateTime(2026, 9, 2, 9, 41);
  final entries = <WeightEntry>[];
  for (int i = 0; i < 90; i++) {
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

  // Configurable target device (default: 'android/phone')
  const screenshotDevice = String.fromEnvironment(
    'SCREENSHOT_DEVICE',
    defaultValue: 'android/phone',
  );

  // Configurable module filter (default: all modules)
  const screenshotModuleFilter = String.fromEnvironment(
    'SCREENSHOT_MODULE',
    defaultValue: 'all',
  );

  // Optional single locale filter (e.g. 'pl', 'en', or empty for all)
  const screenshotLocaleFilter = String.fromEnvironment(
    'SCREENSHOT_LOCALE',
    defaultValue: '',
  );

  bool shouldRunModule(String module) {
    if (screenshotModuleFilter.isEmpty ||
        screenshotModuleFilter == 'all' ||
        screenshotModuleFilter == 'all_modules') {
      return true;
    }
    return module.toLowerCase().contains(
          screenshotModuleFilter.toLowerCase(),
        ) ||
        screenshotModuleFilter.toLowerCase().contains(module.toLowerCase());
  }

  final effectiveLocales = screenshotLocaleFilter.isNotEmpty
      ? [screenshotLocaleFilter]
      : supportedLocales;

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
    final effectiveWeightBloc =
        weightBloc ??
        (WeightBloc(repository: weightRepo)
          ..add(const SubscribeToWeightChanges()));

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
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);
        final prefix = screenshotDevice.isNotEmpty ? '$screenshotDevice/' : '';

        // ---------------------------------------------------------------------
        // 00_splash (App startup loading screen directly from codebase)
        // ---------------------------------------------------------------------
        if (shouldRunModule('00_splash') || shouldRunModule('splash')) {
          testWidgets('Capture 00_splash [$localeCode] [$themeLabel]', (
            WidgetTester tester,
          ) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: const AppSplashScreen(),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/00_splash/splash_$themeLabel',
            );
          }, tags: 'screenshot');
        }

        // ---------------------------------------------------------------------
        // 01_onboarding
        // ---------------------------------------------------------------------
        if (shouldRunModule('01_onboarding') || shouldRunModule('onboarding')) {
          // 01_onboarding / 01_welcome
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
                    initialTimestamp: DateTime(2026, 9, 2, 9, 41),
                    onNext: (_, _) {},
                  ),
                  locale: locale,
                  theme: theme,
                  themeMode: themeMode,
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
                '$prefix$localeCode/01_onboarding/08_biometric_lock_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 02_today
        // ---------------------------------------------------------------------
        if (shouldRunModule('02_today') || shouldRunModule('today')) {
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const MainNavigationScreen(),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/02_today/01_dashboard_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 02_today / 02_add_measurement
          testWidgets(
            'Capture 02_today/02_add_measurement [$localeCode] [$themeLabel]',
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: Stack(
                      children: [
                        const MainNavigationScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Material(
                            color: Colors.transparent,
                            child: AddWeightSheet(
                              initialDate: DateTime(2026, 9, 2, 9, 41),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/02_today/02_add_measurement_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 02_today / 03_bmi_categories
          testWidgets(
            'Capture 02_today/03_bmi_categories [$localeCode] [$themeLabel]',
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const Stack(
                      children: [
                        MainNavigationScreen(),
                        ModalBarrier(dismissible: false, color: Colors.black54),
                        SafeArea(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Material(
                                color: Colors.transparent,
                                child: BmiLegendDialog(
                                  latestWeightKg: 87.0,
                                  heightCm: 177.0,
                                  currentCategory: BmiCategory.overweight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/02_today/03_bmi_categories_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 03_calendar
        // ---------------------------------------------------------------------
        if (shouldRunModule('03_calendar') || shouldRunModule('calendar')) {
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: CalendarScreen(initialDate: DateTime(2026, 9, 2)),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/03_calendar/01_month_view_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 03_calendar / 02_day_details
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: CalendarScreen(initialDate: DateTime(2026, 9, 20)),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/03_calendar/02_day_details_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 04_statistics
        // ---------------------------------------------------------------------
        if (shouldRunModule('04_statistics') || shouldRunModule('statistics')) {
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const StatisticsScreen(),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/04_statistics/01_overview_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 04_statistics / 02_achievements_gallery
          testWidgets(
            'Capture 04_statistics/02_achievements_gallery [$localeCode] [$themeLabel]',
            (WidgetTester tester) async {
              final evaluatedMilestones = MilestoneCalculator.evaluate(
                entries: mockEntries,
                targetWeight: 85.0,
                heightCm: 177.0,
                goalMode: WeightGoalMode.lose,
              );

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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: Stack(
                      children: [
                        const StatisticsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Material(
                            color: Colors.transparent,
                            child: MilestonesGallerySheet(
                              milestones: evaluatedMilestones,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/04_statistics/02_achievements_gallery_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 05_settings
        // ---------------------------------------------------------------------
        if (shouldRunModule('05_settings') || shouldRunModule('settings')) {
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const SettingsScreen(),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/05_settings/01_preferences_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 05_settings / 02_target_weight_sheet
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
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const Stack(
                      children: [
                        SettingsScreen(),
                        ModalBarrier(dismissible: false, color: Colors.black54),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Material(
                            color: Colors.transparent,
                            child: TargetWeightSheet(
                              currentValueKg: 85.0,
                              measurementUnit: MeasurementUnit.metric,
                              initialGoalMode: WeightGoalMode.lose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              await binding.takeScreenshot(
                '$prefix$localeCode/05_settings/02_target_weight_sheet_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 05_settings / 03_privacy_policy
          testWidgets(
            'Capture 05_settings/03_privacy_policy [$localeCode] [$themeLabel]',
            (WidgetTester tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: const PrivacyPolicyScreen(),
                ),
              );

              await tester.pumpAndSettle();
              await binding.takeScreenshot(
                '$prefix$localeCode/05_settings/03_privacy_policy_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 06_biometric
        // ---------------------------------------------------------------------
        if (shouldRunModule('06_biometric') || shouldRunModule('biometric')) {
          testWidgets(
            'Capture 06_biometric/01_biometric_lock [$localeCode] [$themeLabel]',
            (WidgetTester tester) async {
              final settingsBloc = AppSettingsBloc()
                ..add(const UpdateBiometricLock(true))
                ..add(const SetLocked(true));

              await tester.pumpWidget(
                BlocProvider<AppSettingsBloc>.value(
                  value: settingsBloc,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: theme,
                    themeMode: themeMode,
                    home: const BiometricShieldScreen(),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              await binding.takeScreenshot(
                '$prefix$localeCode/06_biometric/01_biometric_lock_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }

        // ---------------------------------------------------------------------
        // 07_home_widgets
        // ---------------------------------------------------------------------
        if (shouldRunModule('07_home_widgets') ||
            shouldRunModule('home_widgets')) {
          testWidgets(
            'Capture 07_home_widgets/01_widget_2x1 [$localeCode] [$themeLabel]',
            (WidgetTester tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: Scaffold(
                    body: WidgetPreviewCanvas(
                      title: 'Widget 2 × 1',
                      isDark: isDark,
                      child: HomeWidget2x1View(
                        currentWeight: 87.0,
                        unit: 'kg',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              await binding.takeScreenshot(
                '$prefix$localeCode/07_home_widgets/01_widget_2x1_$themeLabel',
              );
            },
            tags: 'screenshot',
          );

          // 07_home_widgets / 02_widget_3x2
          testWidgets(
            'Capture 07_home_widgets/02_widget_3x2 [$localeCode] [$themeLabel]',
            (WidgetTester tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: theme,
                  themeMode: themeMode,
                  home: Scaffold(
                    body: WidgetPreviewCanvas(
                      title: 'Widget 3 × 2',
                      isDark: isDark,
                      child: HomeWidget3x2View(
                        currentWeight: 87.0,
                        targetWeight: 85.0,
                        delta: -0.2,
                        unit: 'kg',
                        bmiCategory: BmiCategory.overweight,
                        bmiValue: 27.8,
                        goalProgressPct: 73,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              await binding.takeScreenshot(
                '$prefix$localeCode/07_home_widgets/02_widget_3x2_$themeLabel',
              );
            },
            tags: 'screenshot',
          );
        }
      }
    }
  });
}

/// Canvas wrapper to present home widgets cleanly in screenshots.
class WidgetPreviewCanvas extends StatelessWidget {
  final Widget child;
  final String title;
  final bool isDark;

  const WidgetPreviewCanvas({
    super.key,
    required this.child,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1117), Color(0xFF141721), Color(0xFF1A1D29)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9EEF5), Color(0xFFF3F6FA), Color(0xFFE3E9F2)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: bgGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFFC4C7D0)
                      : const Color(0xFF555B68),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Visual representation of the compact 2x1 home screen widget.
class HomeWidget2x1View extends StatelessWidget {
  final double currentWeight;
  final String unit;
  final bool isDark;

  const HomeWidget2x1View({
    super.key,
    required this.currentWeight,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE2E4E9);
    final textHeader = isDark
        ? const Color(0xFFC4C7D0)
        : const Color(0xFF44474F);
    final primaryBlue = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);
    final buttonBg = isDark ? const Color(0xFF2A3140) : const Color(0xFFE8F0FE);
    final buttonIconColor = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);

    return Container(
      width: 336,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Balance • ${l10n.today}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textHeader,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentWeight.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textHeader,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: buttonBg, shape: BoxShape.circle),
            child: Icon(Icons.add, color: buttonIconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Visual representation of the full 3x2 home screen widget.
class HomeWidget3x2View extends StatelessWidget {
  final double currentWeight;
  final double targetWeight;
  final double delta;
  final String unit;
  final BmiCategory bmiCategory;
  final double bmiValue;
  final int goalProgressPct;
  final bool isDark;

  const HomeWidget3x2View({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.delta,
    required this.unit,
    required this.bmiCategory,
    required this.bmiValue,
    required this.goalProgressPct,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cardBg = isDark ? const Color(0xFF1E2128) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE2E4E9);
    final textHeader = isDark
        ? const Color(0xFFC4C7D0)
        : const Color(0xFF44474F);
    final primaryBlue = isDark
        ? const Color(0xFFA8C7FA)
        : const Color(0xFF005BDE);
    final progressBg = isDark
        ? const Color(0xFF2E333D)
        : const Color(0xFFE5E7EB);

    final isLoss = delta <= 0;
    final chipBg = isLoss
        ? (isDark ? const Color(0xFF1B3B1E) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFEBEE));
    final chipTextColor = isLoss
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));

    final bmiBg = isDark ? const Color(0xFF3E2E1E) : const Color(0xFFFFF3E0);
    final bmiTextColor = isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFEF6C00);

    final deltaStr = isLoss
        ? '${delta.toStringAsFixed(1)} $unit'
        : '+${delta.toStringAsFixed(1)} $unit';

    return Container(
      width: 348,
      height: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance • ${l10n.today}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textHeader,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentWeight.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textHeader,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            deltaStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.today}, 08:30',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textHeader.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bmiBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bmiCategory.localizedName(l10n),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: bmiTextColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'BMI ${bmiValue.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: bmiTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.chartTargetLabel}: ${targetWeight.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textHeader,
                    ),
                  ),
                  Text(
                    '$goalProgressPct%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: progressBg,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (goalProgressPct / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
