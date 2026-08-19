import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A tonal badge summarizing the weight change across the active chart period.
class WeightDeltaChip extends StatelessWidget {
  /// The entries included in the active chart period.
  final List<WeightEntry> entries;

  /// The unit used to format the displayed delta.
  final MeasurementUnit measurementUnit;

  /// Creates a [WeightDeltaChip].
  const WeightDeltaChip({
    super.key,
    required this.entries,
    required this.measurementUnit,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final deltaKg = sortedEntries.length < 2
        ? 0.0
        : sortedEntries.last.weightKg - sortedEntries.first.weightKg;
    final delta = measurementUnit == MeasurementUnit.imperial
        ? kgToLbs(deltaKg)
        : deltaKg;
    final isLoss = delta < 0;
    final isGain = delta > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isLoss
        ? Colors.green.withValues(alpha: 0.15)
        : isGain
        ? Colors.orange.withValues(alpha: 0.15)
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final foregroundColor = isLoss
        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
        : isGain
        ? (isDark ? Colors.orange.shade300 : Colors.orange.shade800)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isLoss
        ? Icons.trending_down_rounded
        : isGain
        ? Icons.trending_up_rounded
        : Icons.remove_rounded;
    final unitLabel = measurementUnit == MeasurementUnit.imperial ? 'lb' : 'kg';
    final prefix = isGain ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            '$prefix${delta.toStringAsFixed(1)} $unitLabel',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
