import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/utils/string_capitalize.dart';

/// Displays the focused month and year with previous/next navigation
/// controls wired to [onPreviousMonth] and [onNextMonth].
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
    ).format(focusedMonth).capitalizeFirst();

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                monthYearStr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
                  onPressed: onPreviousMonth,
                  tooltip: l10n.previousMonth,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
                  onPressed: onNextMonth,
                  tooltip: l10n.nextMonth,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
