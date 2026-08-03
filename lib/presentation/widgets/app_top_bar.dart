import 'package:flutter/material.dart';

/// Reusable Material 3 top app bar for main navigation screens.
///
/// Displays a unified 64dp toolbar with the primary weight scale branding icon,
/// localized screen title, and optional action buttons.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text to display in the app bar.
  final String title;

  /// Optional list of action widgets displayed on the right.
  final List<Widget>? actions;

  /// Creates an [AppTopBar] widget.
  const AppTopBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_weight, color: colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
