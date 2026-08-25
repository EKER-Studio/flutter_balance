import 'package:flutter/material.dart';

/// A responsive layout helper that clamps its [child] to a maximum width and centers it horizontally.
class ClampedLayout extends StatelessWidget {
  final Widget child;

  /// Optional uniform padding applied inside the clamped area.
  final EdgeInsetsGeometry? padding;

  final double maxWidth;

  final AlignmentGeometry alignment;

  /// Creates a [ClampedLayout] with the given [child], optional [padding], [maxWidth], and [alignment].
  const ClampedLayout({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 600,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
