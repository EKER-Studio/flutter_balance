import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';

/// A tonal badge summarizing the BMI change across the active chart period.
class BmiDeltaChip extends StatelessWidget {
  /// The entries included in the active chart period.
  final List<WeightEntry> entries;

  /// The user's height in centimeters.
  final double heightCm;

  const BmiDeltaChip({
    super.key,
    required this.entries,
    required this.heightCm,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final hMeters = heightCm / 100.0;
    final hSquared = hMeters * hMeters;

    final double deltaBmi;
    if (sortedEntries.length < 2 || hSquared <= 0) {
      deltaBmi = 0.0;
    } else {
      final firstBmi = sortedEntries.first.weightKg / hSquared;
      final latestBmi = sortedEntries.last.weightKg / hSquared;
      deltaBmi = latestBmi - firstBmi;
    }

    final isLoss = deltaBmi < -0.05;
    final isGain = deltaBmi > 0.05;
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

    final String formattedDelta;
    if (isGain) {
      formattedDelta = '+${deltaBmi.toStringAsFixed(1)}';
    } else if (isLoss) {
      formattedDelta = deltaBmi.toStringAsFixed(1);
    } else {
      formattedDelta = '0.0';
    }

    return Semantics(
      container: true,
      label: 'BMI change: $formattedDelta',
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
