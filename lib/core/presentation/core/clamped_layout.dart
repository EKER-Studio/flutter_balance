
import 'package:flutter/material.dart';

/// A responsive layout helper that clamps content width to 600 px on large screens.
///
/// A stateless widget that constrains its [child] to a maximum width of 600px and
//// centers it.
class ClampedLayout extends StatelessWidget {
  /// The widget to constrain and center.
  final Widget child;

  /// Optional uniform padding applied inside the clamped area.
  final EdgeInsetsGeometry? padding;

  /// Creates a [ClampedLayout] with the given [child] and optional [padding].
  const ClampedLayout({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
