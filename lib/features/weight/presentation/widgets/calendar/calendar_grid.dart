import 'package:flutter/material.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_cell.dart';

/// Callback signature when a calendar day is selected.
typedef OnCalendarDaySelected =
    void Function(DateTime date, List<WeightEntry> entries);

/// Reusable calendar grid displaying day cells for a focused month.
class CalendarGrid extends StatelessWidget {
  /// The month and year currently displayed by the grid.
  final DateTime focusedMonth;

  /// The currently active selected date.
  final DateTime selectedDate;

  /// All available weight entries to map into calendar dates.
  final List<WeightEntry> entries;

  /// Optional target weight in kg used to compute goal achievement markers.
  final double? targetWeight;

  /// Callback triggered when a day cell is tapped.
  final OnCalendarDaySelected onDaySelected;

  /// Creates a [CalendarGrid] widget.
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
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
          onTap: () => onDaySelected(date, dayEntries),
        );
      },
    );
  }
}
