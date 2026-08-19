import 'package:flutter/material.dart';

/// A presentational widget displaying a single habit or activity metric item with an icon, label, and bold value.
class HabitMetricItem extends StatelessWidget {
  /// The icon representing the metric.
  final IconData icon;

  /// The color for [icon].
  final Color iconColor;

  /// The label describing the metric.
  final String label;

  /// The formatted value string.
  final String value;

  /// Creates a [HabitMetricItem] widget.
  const HabitMetricItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
