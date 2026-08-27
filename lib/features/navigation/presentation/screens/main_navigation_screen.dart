import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
/// Supports integration with [StatefulNavigationShell] from `go_router` for deep linking
/// and preserved tab back-stacks, while maintaining fallback support for standalone widget tests.
class MainNavigationScreen extends StatefulWidget {
  /// Optional navigation shell provided by [StatefulShellRoute].
  final StatefulNavigationShell? navigationShell;

  const MainNavigationScreen({super.key, this.navigationShell});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

/// State holding the active tab index and rendering the selected screen.
class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _tabNames = ['today', 'calendar', 'stats', 'settings'];

  int get _activeTabIndex =>
      widget.navigationShell?.currentIndex ?? _currentIndex;

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

    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
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
    final selectedIndex = _activeTabIndex;

    final Widget body;
    if (widget.navigationShell != null) {
      body = widget.navigationShell!;
    } else {
      final screens = [
        TodayScreen(onNavigateToSettings: () => _onTabSelected(3)),
        const CalendarScreen(),
        const StatisticsScreen(),
        const SettingsScreen(),
      ];
      body = IndexedStack(index: _currentIndex, children: screens);
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              AdaptiveNavigationRail(
                selectedIndex: selectedIndex,
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
      extendBodyBehindAppBar: true,
      body: body,
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onTabSelected,
      ),
    );
  }
}
