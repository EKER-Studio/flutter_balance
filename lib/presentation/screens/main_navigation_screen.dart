import 'package:flutter/material.dart';
import 'package:pure_weight/features/weight/presentation/screens/calendar_screen.dart';
import 'package:pure_weight/features/weight/presentation/screens/statistics_screen.dart';
import 'package:pure_weight/features/weight/presentation/screens/today_screen.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';

/// Main container screen featuring a 4-tab Material 3 Bottom Navigation Bar.
class MainNavigationScreen extends StatefulWidget {
  /// Creates [MainNavigationScreen].
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

/// Holds the active tab index and renders the selected screen.
class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// Switches the active tab to [index].
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final screens = [
      TodayScreen(onNavigateToSettings: () => _onTabSelected(3)),
      const CalendarScreen(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 80,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
            indicatorColor: colorScheme.secondaryContainer,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.focused)) {
                return colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.48,
                );
              }
              return null;
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: colorScheme.onSecondaryContainer);
              }
              return IconThemeData(color: colorScheme.onSurfaceVariant);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final base = textTheme.labelMedium;
              if (states.contains(WidgetState.selected)) {
                return base?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                );
              }
              return base?.copyWith(color: colorScheme.onSurfaceVariant);
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            destinations: [
              Semantics(
                selected: _currentIndex == 0,
                label: l10n.todayTabHomeSemanticsLabel,
                child: NavigationDestination(
                  icon: const Icon(Icons.today_outlined),
                  selectedIcon: const Icon(Icons.today, fill: 1),
                  label: l10n.tabToday,
                ),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: l10n.tabCalendar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: l10n.tabStats,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.tabSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
