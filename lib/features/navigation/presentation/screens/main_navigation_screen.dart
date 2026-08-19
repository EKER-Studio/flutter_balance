// Root scaffold hosting the app's four-tab navigation shell.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';
import 'package:balance/features/navigation/presentation/widgets/components/adaptive_bottom_navigation_bar.dart';
import 'package:balance/features/navigation/presentation/widgets/components/adaptive_navigation_rail.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// Main container screen featuring adaptive navigation (NavigationBar in portrait, NavigationRail in landscape).
///
/// The destinations are ordered Today, Calendar, Statistics, and Settings and
/// match the screen list order, so the selected index directly selects the
/// visible child of the [IndexedStack] — swapping tabs without losing per-tab
/// state. Tab switching, focus traversal, and keyboard handling are delegated
/// to the navigation bar/rail semantics via `onDestinationSelected`;
/// `home`-style navigation from the Today screen jumps to the Settings tab.
class MainNavigationScreen extends StatefulWidget {
  /// Creates [MainNavigationScreen].
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

/// State holding the active tab index and rendering the selected screen.
class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _tabNames = ['today', 'calendar', 'stats', 'settings'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppAnalytics.logTodayScreenViewed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Switches the active tab to [index].
  void _onTabSelected(int index) {
    if (index >= 0 && index < _tabNames.length) {
      final tabName = _tabNames[index];
      AppAnalytics.logNavigationTabSwitched(tabIndex: index, tabName: tabName);
      switch (index) {
        case 0:
          AppAnalytics.logTodayScreenViewed();
        case 1:
          AppAnalytics.logCalendarScreenViewed();
        case 2:
          AppAnalytics.logStatisticsScreenViewed();
        case 3:
          AppAnalytics.logSettingsScreenViewed();
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final settings = context.read<AppSettingsBloc>().state;
      if (settings.isHealthSyncEnabled) {
        context.read<WeightBloc>().add(const SyncHealthEntries());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final screens = [
      TodayScreen(onNavigateToSettings: () => _onTabSelected(3)),
      const CalendarScreen(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final body = IndexedStack(index: _currentIndex, children: screens);

    if (isLandscape) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              AdaptiveNavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabSelected,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
      ),
    );
  }
}
