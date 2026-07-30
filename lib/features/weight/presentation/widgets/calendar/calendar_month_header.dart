import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable month navigation header for calendar views.
class CalendarMonthHeader extends StatelessWidget {
  /// The currently displayed month and year.
  final DateTime focusedMonth;

  /// Callback invoked when navigating to the previous month.
  final VoidCallback onPreviousMonth;

  /// Callback invoked when navigating to the next month.
  final VoidCallback onNextMonth;

  /// Creates a [CalendarMonthHeader] widget.
  const CalendarMonthHeader({
    super.key,
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthYearStr = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(focusedMonth);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
              tooltip: 'Previous month',
            ),
            Text(
              monthYearStr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
              tooltip: 'Next month',
            ),
          ],
        ),
      ),
    );
  }
}
