import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_month_header.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_weekday_header.dart';
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

  /// Callback when the previous month button is pressed.
  final VoidCallback onPreviousMonth;

  /// Callback when the next month button is pressed.
  final VoidCallback onNextMonth;

  /// Callback when a day in the grid is selected.
  final ValueChanged<DateTime> onDaySelected;

  /// Creates a [CalendarMonthCard] widget.
  const CalendarMonthCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.entries,
    required this.targetWeight,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          isLandscape ? 16 : 16,
          0,
          isLandscape ? 16 : 20,
        ),
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
            SizedBox(height: isLandscape ? 12 : 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CalendarWeekdayHeader(),
            ),
            SizedBox(height: isLandscape ? 10 : 12),
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
