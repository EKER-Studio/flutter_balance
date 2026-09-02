import 'package:flutter/material.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_cell.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A fixed 7-column grid of [CalendarDayCell]s for a focused month.
class CalendarGrid extends StatelessWidget {
  /// The month and year currently displayed by the grid.
  final DateTime focusedMonth;

  /// The currently active selected date.
  final DateTime selectedDate;

  /// All available [WeightEntry] records to map into calendar dates.
  final List<WeightEntry> entries;

  /// An optional target weight in kilograms used to compute goal achievement markers.
  final double? targetWeight;

  /// The preferred first day of the week.
  final FirstDayOfWeek firstDayOfWeek;

  /// The active goal mode.
  final WeightGoalMode goalMode;

  /// The callback triggered when a day cell is tapped.
  final void Function(DateTime date, List<WeightEntry> entries) onDaySelected;

  const CalendarGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.entries,
    this.targetWeight,
    this.firstDayOfWeek = FirstDayOfWeek.system,
    this.goalMode = WeightGoalMode.lose,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);

    int startingOffset;
    switch (firstDayOfWeek) {
      case FirstDayOfWeek.monday:
        startingOffset = (firstDayOfMonth.weekday - 1) % 7;
      case FirstDayOfWeek.sunday:
        startingOffset = firstDayOfMonth.weekday % 7;
      case FirstDayOfWeek.system:
        final systemFirstDayIndex = MaterialLocalizations.of(
          context,
        ).firstDayOfWeekIndex;
        startingOffset =
            (firstDayOfMonth.weekday % 7 - systemFirstDayIndex + 7) % 7;
    }

    final totalCells = startingOffset + daysInMonth;

    final Map<int, List<WeightEntry>> entriesByDay = {};
    for (final e in entries) {
      if (e.dateTime.year == focusedMonth.year &&
          e.dateTime.month == focusedMonth.month) {
        entriesByDay.putIfAbsent(e.dateTime.day, () => []).add(e);
      }
    }

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    bool isEntryGoalAchieved(WeightEntry e) {
      if (targetWeight != null) {
        switch (goalMode) {
          case WeightGoalMode.lose:
            return e.weightKg <= targetWeight!;
          case WeightGoalMode.gain:
            return e.weightKg >= targetWeight!;
          case WeightGoalMode.maintain:
            return (e.weightKg - targetWeight!).abs() <= 1.0;
        }
      }
      return false;
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      clipBehavior: Clip.none,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        mainAxisExtent: 40,
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
            targetWeight != null && dayEntries.any(isEntryGoalAchieved);

        return CalendarDayCell(
          date: date,
          dayNumber: dayNumber,
          entries: dayEntries,
          isToday: isToday,
          isSelected: isSelected,
          isFuture: isFuture,
          isGoalAchieved: isGoalAchieved,
          targetWeight: targetWeight,
          goalMode: goalMode,
          onTap: isFuture ? null : () => onDaySelected(date, dayEntries),
        );
      },
    );
  }
}
