import 'package:flutter/material.dart';

/// A widget that renders a section header label above each settings group.
class SectionHeader extends StatelessWidget {
  final String label;

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
