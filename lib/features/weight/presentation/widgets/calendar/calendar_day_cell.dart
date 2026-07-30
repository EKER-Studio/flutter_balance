import 'package:flutter/material.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Reusable calendar day cell widget displaying day number and status indicators.
class CalendarDayCell extends StatelessWidget {
  /// The specific date represented by this cell.
  final DateTime date;

  /// The day number of the month (1-31).
  final int dayNumber;

  /// List of weight entries recorded on this date.
  final List<WeightEntry> entries;

  /// Whether this cell represents the current date.
  final bool isToday;

  /// Callback when this cell is tapped.
  final VoidCallback onTap;

  /// Creates a [CalendarDayCell] widget.
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.entries,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries.isNotEmpty;
    final isMultiple = entries.length > 1;

    final cs = Theme.of(context).colorScheme;
    final backgroundColor = isToday
        ? cs.primaryContainer
        : hasEntries
            ? cs.secondaryContainer
            : cs.surfaceContainerLow;

    final textColor = isToday
        ? cs.onPrimaryContainer
        : hasEntries
            ? cs.onSecondaryContainer
            : cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: cs.primary, width: 2)
              : hasEntries
                  ? null
                  : Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight:
                        isToday || hasEntries ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            const SizedBox(height: 4),
            if (hasEntries)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday ? cs.primary : cs.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (isMultiple) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isToday ? cs.primary : cs.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              )
            else
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
