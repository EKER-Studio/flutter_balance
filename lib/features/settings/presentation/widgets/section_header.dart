import 'package:flutter/material.dart';

/// Section header label rendered above each settings group.
class SectionHeader extends StatelessWidget {
  /// The section title text.
  final String label;

  /// Creates a [SectionHeader] with the given [label].
  const SectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

/// Tappable settings list tile with icon, title, optional supporting text and
/// trailing value, error styling, and keyboard focus ring for accessibility.
