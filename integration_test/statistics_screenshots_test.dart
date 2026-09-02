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
import 'package:balance/features/statistics/presentation/utils/milestone_icon_resolver.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestones_gallery_sheet.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/period_comparison_card.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:intl/intl.dart';
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
                    showNotificationIcon: true,
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
                    showNotificationIcon: true,
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

        // 04_statistics / 03_achievement_detail (gallery + detail dialog on top)
        testWidgets(
          'Capture 04_statistics/03_achievement_detail [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final evaluatedMilestones = MilestoneCalculator.evaluate(
              entries: generate90MockEntries(),
              targetWeight: 85.0,
              heightCm: 177.0,
              goalMode: WeightGoalMode.lose,
            );

            // Pick first unlocked milestone (e.g. "Pierwszy krok" / "First Step")
            final milestone = evaluatedMilestones.firstWhere(
              (m) => m.isUnlocked && m.unlockedDate != null,
              orElse: () => evaluatedMilestones.first,
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
                    showNotificationIcon: true,
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
                        // Detail dialog overlay (as if user tapped a badge)
                        const ModalBarrier(
                          dismissible: false,
                          color: Colors.black54,
                        ),
                        Center(
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              final cs = Theme.of(context).colorScheme;
                              final isDarkTheme =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final title = milestone.type.localizedTitle(l10n);
                              final description = milestone.type
                                  .localizedDescription(l10n);
                              return AlertDialog(
                                scrollable: true,
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                icon: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: milestone.isUnlocked
                                        ? cs.primaryContainer
                                        : cs.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconForMilestone(milestone.type),
                                    size: 26,
                                    color: milestone.isUnlocked
                                        ? cs.primary
                                        : cs.onSurfaceVariant.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                title: Text(title, textAlign: TextAlign.center),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      description,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (milestone.isUnlocked &&
                                        milestone.unlockedDate != null) ...[
                                      Text(
                                        DateFormat.yMMMMd(
                                          l10n.localeName,
                                        ).format(milestone.unlockedDate!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: isDarkTheme
                                                  ? Colors.green.shade400
                                                  : Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          height: 6,
                                          width: double.infinity,
                                          color: isDarkTheme
                                              ? Colors.green.shade400
                                              : Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).okButtonLabel,
                                    ),
                                  ),
                                ],
                              );
                            },
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
              '$prefix$localeCode/04_statistics/03_achievement_detail_$themeLabel',
            );
          },
          tags: 'screenshot',
        );

        // 04_statistics / 04_period_comparison_scrolled (PeriodComparison at top)
        testWidgets(
          'Capture 04_statistics/04_period_comparison_scrolled [$localeCode] [$themeLabel]',
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
                    child: const StatisticsScreen(),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            // Scroll until PeriodComparison card is at the top (below AppTopBar)
            final scrollable = find.byType(CustomScrollView);
            expect(scrollable, findsOneWidget);

            // Repeated drags to bring lower content into view
            for (int i = 0; i < 6; i++) {
              await tester.drag(scrollable, const Offset(0, -400));
              await tester.pumpAndSettle();
            }

            // Ensure PeriodComparison is visible near top
            final periodComparison = find.byType(PeriodComparisonCard);
            expect(periodComparison, findsOneWidget);

            await binding.takeScreenshot(
              '$prefix$localeCode/04_statistics/04_period_comparison_scrolled_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
