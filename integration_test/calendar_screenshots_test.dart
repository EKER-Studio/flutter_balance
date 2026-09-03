@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/navigation/presentation/widgets/components/adaptive_bottom_navigation_bar.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
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

  group('03_calendar Screenshot Generator', () {
    for (final localeCode in effectiveLocales) {
      final locale = Locale(localeCode);

      for (final isDark in [false, true]) {
        final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
        final themeLabel = isDark ? 'dark' : 'light';

        // 03_calendar / 01_month_view
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
                  home: ScreenshotDeviceFrame(
                    isDark: isDark,
                    showNotificationIcon: true,
                    child: Scaffold(
                      body: CalendarScreen(initialDate: DateTime(2026, 8, 14)),
                      bottomNavigationBar: AdaptiveBottomNavigationBar(
                        selectedIndex: 1,
                        onDestinationSelected: (_) {},
                      ),
                    ),
                  ),
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

        // 03_calendar / 02_edit_measurement
        testWidgets(
          'Capture 03_calendar/02_edit_measurement [$localeCode] [$themeLabel]',
          (WidgetTester tester) async {
            final settingsBloc = AppSettingsBloc()
              ..add(const UpdateHeight(177.0))
              ..add(const TargetWeightChanged(85.0, WeightGoalMode.lose));

            final weightBloc = WeightBloc(repository: weightRepo)
              ..add(const SubscribeToWeightChanges());

            final editEntry = WeightEntry(
              id: 26,
              weightKg: 87.0,
              dateTime: DateTime(2026, 8, 26, 9, 41),
              note: getMockRunNote(localeCode),
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
                    child: Scaffold(
                      body: Stack(
                        children: [
                          CalendarScreen(initialDate: DateTime(2026, 8, 26)),
                          const ModalBarrier(
                            dismissible: false,
                            color: Colors.black54,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: ScreenshotBottomSheetContainer(
                              child: AddWeightSheet(existingEntry: editEntry),
                            ),
                          ),
                        ],
                      ),
                      bottomNavigationBar: AdaptiveBottomNavigationBar(
                        selectedIndex: 1,
                        onDestinationSelected: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            );

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            await binding.takeScreenshot(
              '$prefix$localeCode/03_calendar/02_edit_measurement_$themeLabel',
            );
          },
          tags: 'screenshot',
        );
      }
    }
  });
}
