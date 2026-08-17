import 'package:flutter/material.dart';

/// A responsive layout helper that clamps content width to 600 px on large screens.
///
/// A stateless widget that constrains its [child] to a maximum width of 600px and
/// centers it.
class ClampedLayout extends StatelessWidget {
  /// The widget to constrain and center.
  final Widget child;

  /// Optional uniform padding applied inside the clamped area.
  final EdgeInsetsGeometry? padding;

  /// The maximum allowed width for the clamped content box.
  final double maxWidth;

  /// Creates a [ClampedLayout] with the given [child], optional [padding], and [maxWidth].
  const ClampedLayout({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
