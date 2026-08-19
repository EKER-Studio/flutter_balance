import 'package:flutter/material.dart';

/// A presentational row widget displaying a weight statistic with an icon, title, date subtitle, and value.
class WeightDetailRow extends StatelessWidget {
  /// The icon representing the metric.
  final IconData icon;

  /// The color for [icon].
  final Color iconColor;

  /// The label for the row (e.g., Highest, Lowest, Average).
  final String label;

  /// The formatted value string (e.g., '72.5 kg').
  final String value;

  /// The formatted date string corresponding to the measurement.
  final String date;

  /// Creates a [WeightDetailRow] widget.
  const WeightDetailRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MergeSemantics(
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 24, color: iconColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
