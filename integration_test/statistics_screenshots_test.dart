@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestones_gallery_sheet.dart';
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

  group('04_statistics Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      for (final isDark in [false, true]) {
        final themeLabel = isDark ? 'dark' : 'light';
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final locale = Locale(localeCode);

        // 04_statistics / 01_overview
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    child: const StatisticsScreen(),
                  ),
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

        // 04_statistics / 02_achievements_gallery (on top of real StatisticsScreen)
        testWidgets(
          'Capture 04_statistics/02_achievements_gallery [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final evaluatedMilestones = MilestoneCalculator.evaluate(
              entries: generate90MockEntries(),
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    child: Stack(
                      children: [
                        const StatisticsScreen(),
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: ScreenshotBottomSheetContainer(
                            child: MilestonesGallerySheet(
                              milestones: evaluatedMilestones,
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
              '$prefix$localeCode/04_statistics/02_achievements_gallery_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
