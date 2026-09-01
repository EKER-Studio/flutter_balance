import 'package:flutter/material.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';

/// A generic responsive layout container for onboarding wizard steps.
///
/// Structures the screen into three distinct vertical zones:
/// 1. **Header**: Top-anchored [title] and [subtitle] (or custom widgets).
/// 2. **Body**: Middle flexible [content] (form fields, feature cards, toggles).
/// 3. **Footer**: Bottom-anchored [footer] (action buttons like `Next`, `Skip`).
///
/// In portrait viewports, the [footer] is pinned to the bottom of the screen.
/// In landscape or keyboard-constrained viewports, the layout smoothly scrolls
/// without any `RenderFlex` overflow errors.
class OnboardingStepLayout extends StatelessWidget {
  /// Optional title text displayed in the header.
  final String? title;

  /// Optional custom title widget for specialized formatting.
  final Widget? titleWidget;

  /// Optional subtitle text displayed below the title.
  final String? subtitle;

  /// Optional custom subtitle widget.
  final Widget? subtitleWidget;

  /// The interactive step content occupying the middle region.
  final Widget content;

  /// The bottom-anchored action button or action row.
  final Widget footer;

  /// Optional custom padding override.
  final EdgeInsetsGeometry? padding;

  /// Whether to vertically center the [content] inside the available middle space.
  /// Defaults to `false` (aligned to the top with standard header spacing).
  final bool centerContent;

  const OnboardingStepLayout({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    required this.content,
    required this.footer,
    this.padding,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: isLandscape ? 12.0 : 24.0,
        );

    return ClampedLayout(
      maxWidth: 520,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isLandscape) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: effectivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (titleWidget != null)
                      titleWidget!
                    else if (title != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        title!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (subtitleWidget != null)
                      subtitleWidget!
                    else if (subtitle != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8.0),

                    Align(
                      alignment: centerContent
                          ? Alignment.center
                          : Alignment.topCenter,
                      child: content,
                    ),

                    const SizedBox(height: 12.0),

                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: footer,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: effectivePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (titleWidget != null)
                        titleWidget!
                      else if (title != null) ...[
                        Text(
                          title!,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (subtitleWidget != null)
                        subtitleWidget!
                      else if (subtitle != null) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24.0),

                      Expanded(
                        child: Align(
                          alignment: centerContent
                              ? Alignment.center
                              : Alignment.topCenter,
                          child: content,
                        ),
                      ),

                      const SizedBox(height: 24.0),

                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        child: footer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
