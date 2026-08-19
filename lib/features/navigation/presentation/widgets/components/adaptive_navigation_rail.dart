import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

/// An adaptive navigation rail used in landscape mode.
class AdaptiveNavigationRail extends StatelessWidget {
  /// Currently selected tab index.
  final int selectedIndex;

  /// Callback when a tab is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Creates an [AdaptiveNavigationRail] widget.
  const AdaptiveNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return NavigationRailTheme(
      data: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: 0.0,
                  minWidth: 88.0,
                  backgroundColor: colorScheme.surfaceContainer,
                  destinations: [
                    NavigationRailDestination(
                      icon: Semantics(
                        selected: selectedIndex == 0,
                        label: l10n.todayTabHomeSemanticsLabel,
                        child: const Icon(Icons.today_outlined),
                      ),
                      selectedIcon: Semantics(
                        selected: selectedIndex == 0,
                        label: l10n.todayTabHomeSemanticsLabel,
                        child: const Icon(Icons.today, fill: 1),
                      ),
                      label: Text(l10n.tabToday),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month),
                      label: Text(l10n.tabCalendar),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights),
                      label: Text(l10n.tabStats),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings),
                      label: Text(l10n.tabSettings),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
