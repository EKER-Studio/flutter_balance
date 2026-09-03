@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/settings/presentation/widgets/components/first_day_of_week_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/height_sheet.dart';
import 'package:balance/features/settings/presentation/widgets/components/pace_window_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/target_weight_sheet.dart';
import 'package:balance/features/settings/presentation/widgets/components/theme_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/unit_selection_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/csv_import_preview_dialog.dart';
import 'package:balance/features/settings/presentation/widgets/components/wipe_data_dialog.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'helpers/screenshot_test_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final effectiveLocales = getEffectiveLocales();
  final prefix = getScreenshotPrefix();
  late FakeWeightRepository weightRepo;

  setUpAll(() async {
    weightRepo = await initScreenshotEnvironment(binding);
  });

  group('05_settings Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 05_settings / 01_preferences
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: const SettingsScreen(),
                  ),
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

        // 05_settings / 02_target_weight_sheet (on top of real SettingsScreen)
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: const Stack(
                      children: [
                        SettingsScreen(),
                        ModalBarrier(dismissible: false, color: Colors.black54),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ScreenshotBottomSheetContainer(
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

        // 05_settings / 03_height_sheet (bottom sheet: 177 cm)
        testWidgets(
          'Capture 05_settings/03_height_sheet [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: const Stack(
                      children: [
                        SettingsScreen(),
                        ModalBarrier(dismissible: false, color: Colors.black54),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ScreenshotBottomSheetContainer(
                            child: HeightSheet(
                              currentValue: 177.0,
                              measurementUnit: MeasurementUnit.metric,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/03_height_sheet_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 04_unit_selection (radio dialog)
        testWidgets(
          'Capture 05_settings/04_unit_selection [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: UnitSelectionDialog(
                            currentUnit: MeasurementUnit.metric,
                            onSelected: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/04_unit_selection_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 05_theme_selection (radio dialog)
        testWidgets(
          'Capture 05_settings/05_theme_selection [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: ThemeSelectionDialog(
                            currentMode: AppThemeMode.system,
                            onSelected: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/05_theme_selection_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 06_pace_window_selection (radio dialog)
        testWidgets(
          'Capture 05_settings/06_pace_window_selection [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: PaceWindowSelectionDialog(
                            currentDays: 30,
                            onSelected: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/06_pace_window_selection_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 07_first_day_of_week_selection (radio dialog)
        testWidgets(
          'Capture 05_settings/07_first_day_of_week_selection [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: FirstDayOfWeekSelectionDialog(
                            currentFirstDay: FirstDayOfWeek.system,
                            onSelected: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/07_first_day_of_week_selection_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 08_wipe_data_dialog (destructive confirmation)
        testWidgets(
          'Capture 05_settings/08_wipe_data_dialog [$localeCode] [$themeLabel]',
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        const Center(child: WipeDataDialog()),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/08_wipe_data_dialog_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 09_csv_import_preview (94 entries, date range)
        testWidgets(
          'Capture 05_settings/09_csv_import_preview [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            // Mock analysis matching the screenshot: 94 entries, 30 May – 31 Aug 2026
            final mockEntries = List.generate(
              94,
              (i) => WeightEntry(
                id: i + 1,
                weightKg: 85.0 + (i % 5) * 0.3,
                dateTime: DateTime(2026, 5, 30).add(Duration(days: i)),
              ),
            );
            final analysis = (
              validEntries: mockEntries,
              skippedRowCount: 0,
              earliestDate: DateTime(2026, 5, 30),
              latestDate: DateTime(2026, 8, 31),
            );

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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const SettingsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: CsvImportPreviewDialog(analysis: analysis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/09_csv_import_preview_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 05_settings / 10_privacy_policy
        testWidgets(
          'Capture 05_settings/10_privacy_policy [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: theme,
                themeMode: themeMode,
                home: ScreenshotDeviceFrame(
                  isDark: isDark,
                  showNotificationIcon: true,
                  child: const PrivacyPolicyScreen(),
                ),
              ),
            );

            await tester.pumpAndSettle();

            await binding.takeScreenshot(
              '$prefix$localeCode/05_settings/10_privacy_policy_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
