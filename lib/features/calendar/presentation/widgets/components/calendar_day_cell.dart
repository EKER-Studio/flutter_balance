// The individual day cell widget displayed in the calendar grid.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A single day cell within the calendar grid.
///
/// Renders the day number centered, an indicator row for recorded weight entries,
/// and an overlaid achievement badge when the day's goal has been reached.
class CalendarDayCell extends StatelessWidget {
  /// The full calendar date represented by this cell.
  final DateTime date;

  /// The day-of-month integer to display.
  final int dayNumber;

  /// All weight entries recorded on this day.
  final List<WeightEntry> entries;

  /// Whether this cell represents the current calendar day.
  final bool isToday;

  /// Whether this cell is currently selected.
  final bool isSelected;

  /// Whether this cell falls after today and is non-interactive.
  final bool isFuture;

  /// Whether any entry on this day reached or beat the target weight.
  final bool isGoalAchieved;

  /// Callback invoked when the user taps on this day cell.
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dayNumber,
    this.entries = const [],
    this.isToday = false,
    this.isSelected = false,
    this.isFuture = false,
    this.isGoalAchieved = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color textColor;
    if (isFuture) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.25);
    } else if (isSelected) {
      textColor = colorScheme.onSurface;
    } else if (isToday) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface;
    }

    final cellDecoration = isSelected
        ? BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 1.5),
          )
        : null;

    final dateFormatted = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    final semanticLabel =
        '$dateFormatted, ${entries.length} measurements${isGoalAchieved ? ', goal achieved' : ''}';

    final isDark = theme.brightness == Brightness.dark;
    final dotColor = isGoalAchieved
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : colorScheme.primary;

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFuture ? null : onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (cellDecoration != null)
                Container(width: 36, height: 36, decoration: cellDecoration),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      '$dayNumber',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 4,
                    child: entries.isNotEmpty
                        ? ExcludeSemantics(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
