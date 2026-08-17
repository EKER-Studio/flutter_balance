import 'package:flutter/material.dart';

/// A top app bar for main navigation screens.
///
/// A reusable Material 3 top app bar for main navigation screens.
///
/// Displays a unified 64dp toolbar with the primary weight scale branding icon,
/// localized screen title, and optional action buttons.
class AppTopBar extends StatelessWidget {
  /// The title text to display in the app bar.
  final String title;

  /// An optional list of action widgets displayed on the right.
  final List<Widget>? actions;

  /// Creates an [AppTopBar] widget.
  const AppTopBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      floating: true,
      snap: true,
      titleSpacing: 16,
      title: Text(
        title,
        style: textTheme.headlineMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
