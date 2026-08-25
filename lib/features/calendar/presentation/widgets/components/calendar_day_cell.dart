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

  /// The target weight used to compute per-entry status colors.
  ///
  /// When provided, each dot is colored individually based on whether
  /// its entry's weight is <= target weight. When null, all dots fall
  /// back to the aggregated [isGoalAchieved] flag.
  final double? targetWeight;

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
    this.targetWeight,
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

    final green = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final blue = colorScheme.primary;

    bool isEntryGoalAchieved(WeightEntry e) {
      if (targetWeight != null) return e.weightKg <= targetWeight!;
      return isGoalAchieved;
    }

    final hasGoalEntry = targetWeight != null
        ? entries.any((e) => e.weightKg <= targetWeight!)
        : isGoalAchieved;

    Widget buildIndicator() {
      if (entries.isEmpty) return const SizedBox.shrink();
      if (entries.length >= 4) {
        final barColor = hasGoalEntry ? green : blue;
        return ExcludeSemantics(
          child: Container(
            width: 12,
            height: 3.5,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }
      // 1..3 entries: individual dots.
      List<Widget> dots = entries.take(3).map((e) {
        final c = isEntryGoalAchieved(e) ? green : blue;
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
      }).toList();

      if (dots.length == 1) {
        return ExcludeSemantics(child: dots.first);
      }
      return ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < dots.length; i++) ...[
              dots[i],
              if (i != dots.length - 1) const SizedBox(width: 2),
            ],
          ],
        ),
      );
    }

    final indicator = buildIndicator();
    final hasIndicator = entries.isNotEmpty;

    return Semantics(
      button: !isFuture,
      selected: isSelected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFuture ? null : onTap,
          customBorder: const CircleBorder(),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: cellDecoration,
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
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
                ),
                if (hasIndicator) const SizedBox(height: 2),
                if (hasIndicator)
                  SizedBox(height: 4, child: Center(child: indicator)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
