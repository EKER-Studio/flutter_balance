@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
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

  group('02_today Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 02_today / 01_dashboard
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: const MainNavigationScreen(),
                  ),
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

        // 02_today / 02_add_measurement (on top of real Today dashboard)
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Stack(
                      children: [
                        const MainNavigationScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ScreenshotBottomSheetContainer(
                            child: AddWeightSheet(
                              initialDate: DateTime(2026, 9, 2, 9, 41),
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
              '$prefix$localeCode/02_today/02_add_measurement_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 02_today / 03_bmi_categories (on top of real Today dashboard)
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: const Stack(
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
    }
  });
}
