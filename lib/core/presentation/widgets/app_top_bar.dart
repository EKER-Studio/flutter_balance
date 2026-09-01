import 'package:flutter/material.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';

/// A reusable Material 3 top app bar for main navigation screens.
///
/// Displays a unified 64dp toolbar with the primary weight scale branding icon,
/// localized screen title, and optional action buttons.
class AppTopBar extends StatelessWidget {
  /// The title text to display in the app bar.
  final String title;

  /// An optional list of action widgets displayed on the right.
  final List<Widget>? actions;

  /// Whether the app bar remains visible at the top when content scrolls.
  ///
  /// When true, the content clips cleanly under the bar without bleeding
  /// into the system status bar.
  final bool pinned;

  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.pinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      floating: false,
      pinned: pinned,
      snap: false,
      titleSpacing: context.contentHorizontalPadding,
      title: Semantics(
        header: true,
        child: Text(
          title,
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      actions: actions,
    );
  }
}
