import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';

/// A tonal badge summarizing the weight change across the active chart period.
class WeightDeltaChip extends StatelessWidget {
  /// The entries included in the active chart period.
  final List<WeightEntry> entries;

  /// The unit used to format the displayed delta.
  final MeasurementUnit measurementUnit;

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
    final BmiCategory? bCategory = isLoss
        ? BmiCategory.normal
        : isGain
        ? BmiCategory.overweight
        : null;
    final foregroundColor = bCategory != null
        ? bCategory.chipContentColor(isDark: isDark)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final backgroundColor = bCategory != null
        ? bCategory.chipBackgroundColor()
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final icon = isLoss
        ? Icons.trending_down_rounded
        : isGain
        ? Icons.trending_up_rounded
        : Icons.remove_rounded;
    final unitLabel = measurementUnit == MeasurementUnit.imperial ? 'lb' : 'kg';
    final prefix = isGain ? '+' : '';
    final formattedDelta = '$prefix${delta.toStringAsFixed(1)} $unitLabel';

    return Semantics(
      container: true,
      label: 'Weight change: $formattedDelta',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: foregroundColor.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 16, color: foregroundColor),
            ),
            const SizedBox(width: 4),
            Text(
              formattedDelta,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
