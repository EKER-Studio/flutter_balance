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
      textColor = colorScheme.onPrimary;
    } else if (isToday) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurface;
    }

    BoxDecoration? cellDecoration;
    if (isSelected) {
      cellDecoration = BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      cellDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      );
    }

    final dateFormatted = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    final semanticLabel =
        '$dateFormatted, ${entries.length} measurements${isGoalAchieved ? ', goal achieved' : ''}';

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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                entries.length.clamp(1, 3),
                                (index) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (isGoalAchieved && !isFuture)
                Positioned(
                  top: 0,
                  right: 0,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
