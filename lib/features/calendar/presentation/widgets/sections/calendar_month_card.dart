import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_month_header.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_weekday_header.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A card section hosting the monthly navigation header, weekday names, and interactive calendar grid.
class CalendarMonthCard extends StatelessWidget {
  /// The month currently focused and displayed by the grid.
  final DateTime focusedMonth;

  /// The currently selected day.
  final DateTime selectedDate;

  /// The recorded weight entries.
  final List<WeightEntry> entries;

  /// An optional target goal weight in kilograms.
  final double? targetWeight;

  /// The preferred first day of the week.
  final FirstDayOfWeek firstDayOfWeek;

  /// The active goal mode.
  final WeightGoalMode goalMode;

  /// Callback when the previous month button is pressed.
  final VoidCallback onPreviousMonth;

  /// Callback when the next month button is pressed.
  final VoidCallback onNextMonth;

  /// Callback when a day in the grid is selected.
  final ValueChanged<DateTime> onDaySelected;

  const CalendarMonthCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.entries,
    required this.targetWeight,
    required this.firstDayOfWeek,
    this.goalMode = WeightGoalMode.lose,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CalendarMonthHeader(
                focusedMonth: focusedMonth,
                onPreviousMonth: onPreviousMonth,
                onNextMonth: onNextMonth,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CalendarWeekdayHeader(firstDayOfWeek: firstDayOfWeek),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 0) {
                    AppAnalytics.logCalendarSwipeMonthChanged('previous');
                    onPreviousMonth();
                  } else if (details.primaryVelocity! < 0) {
                    AppAnalytics.logCalendarSwipeMonthChanged('next');
                    onNextMonth();
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: CalendarGrid(
                    key: ValueKey(focusedMonth),
                    focusedMonth: focusedMonth,
                    selectedDate: selectedDate,
                    entries: entries,
                    targetWeight: targetWeight,
                    firstDayOfWeek: firstDayOfWeek,
                    goalMode: goalMode,
                    onDaySelected: (date, _) => onDaySelected(date),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
