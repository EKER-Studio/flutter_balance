/// Month title and previous/next navigation controls for the calendar.


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Displays the focused month and year with previous/next navigation
///// controls wired to [onPreviousMonth] and [onNextMonth].
class CalendarMonthHeader extends StatelessWidget {
  /// The currently displayed month and year.
  final DateTime focusedMonth;

  /// The callback invoked when navigating to the previous month.
  final VoidCallback onPreviousMonth;

  /// The callback invoked when navigating to the next month.
  final VoidCallback onNextMonth;

  const CalendarMonthHeader({
    super.key,
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthYearStr = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(focusedMonth);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              monthYearStr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPreviousMonth,
                tooltip: l10n.previousMonth,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth,
                tooltip: l10n.nextMonth,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
