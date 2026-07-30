import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Reusable calendar day cell widget with Material 3 styling and accessibility (a11y) support.
class CalendarDayCell extends StatelessWidget {
  /// The date represented by this cell.
  final DateTime date;

  /// The day number of the month (1-31).
  final int dayNumber;

  /// List of weight entries recorded on this date.
  final List<WeightEntry> entries;

  /// Whether this cell represents the current calendar date (today).
  final bool isToday;

  /// Whether this cell is currently selected by the user.
  final bool isSelected;

  /// Callback executed when this cell is tapped.
  final VoidCallback onTap;

  /// Creates a [CalendarDayCell] widget.
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.entries,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries.isNotEmpty;
    final cs = Theme.of(context).colorScheme;

    final dateLabel = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    final entriesCountLabel = hasEntries ? '${entries.length} pomiary' : 'Brak pomiarów';
    final semanticText = '$dateLabel, $entriesCountLabel${isSelected ? ', zaznaczony' : ''}';

    Color circleBgColor;
    Color textColor;
    Color dotColor;

    if (isSelected) {
      circleBgColor = cs.primary;
      textColor = cs.onPrimary;
      dotColor = cs.onPrimary;
    } else if (isToday) {
      circleBgColor = cs.primaryContainer;
      textColor = cs.onPrimaryContainer;
      dotColor = cs.primary;
    } else {
      circleBgColor = Colors.transparent;
      textColor = cs.onSurface;
      dotColor = cs.primary;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticText,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: circleBgColor,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: cs.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected || isToday || hasEntries
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
              if (hasEntries) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
