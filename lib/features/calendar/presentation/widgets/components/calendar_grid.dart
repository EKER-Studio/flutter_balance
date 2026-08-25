// The month grid of day cells shown in the calendar screen.

import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_cell.dart';

/// The callback signature used when a calendar day is selected.
typedef OnCalendarDaySelected =
    void Function(DateTime date, List<WeightEntry> entries);

/// A fixed 7-column grid of [CalendarDayCell]s for a focused month.
///
/// Leading slots before the month's first weekday (Monday-first offset) are
/// left empty, yielding at most 6 rows x 7 columns of square cells. Days
/// after today render faded and are not selectable.
class CalendarGrid extends StatelessWidget {
  /// The month and year currently displayed by the grid.
  final DateTime focusedMonth;

  /// The currently active selected date.
  final DateTime selectedDate;

  /// All available [WeightEntry] records to map into calendar dates.
  final List<WeightEntry> entries;

  /// An optional target weight in kilograms used to compute goal achievement markers.
  final double? targetWeight;

  /// The callback triggered when a day cell is tapped.
  final OnCalendarDaySelected onDaySelected;

  const CalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.entries,
    this.targetWeight,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );

    // DateTime.weekday: Mon=1, Sun=7. Calculate offset for Monday-first calendar.
    final startingOffset = firstDayOfMonth.weekday - 1;
    final totalCells = startingOffset + daysInMonth;

    // Group entries for this month by day
    final Map<int, List<WeightEntry>> entriesByDay = {};
    for (final e in entries) {
      if (e.dateTime.year == focusedMonth.year &&
          e.dateTime.month == focusedMonth.month) {
        entriesByDay.putIfAbsent(e.dateTime.day, () => []).add(e);
      }
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 0,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        // Leave the slots before the month's first weekday empty.
        if (index < startingOffset) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startingOffset + 1;
        final date = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
        final dayEntries = entriesByDay[dayNumber] ?? const [];
        final isToday = DateUtils.isSameDay(date, now);
        final isSelected = DateUtils.isSameDay(date, selectedDate);
        final isFuture = date.isAfter(todayEnd);
        final isGoalAchieved =
            targetWeight != null &&
            dayEntries.any((e) => e.weightKg <= targetWeight!);

        return CalendarDayCell(
          date: date,
          dayNumber: dayNumber,
          entries: dayEntries,
          isToday: isToday,
          isSelected: isSelected,
          isFuture: isFuture,
          isGoalAchieved: isGoalAchieved,
          targetWeight: targetWeight,
          onTap: isFuture ? null : () => onDaySelected(date, dayEntries),
        );
      },
    );
  }
}
