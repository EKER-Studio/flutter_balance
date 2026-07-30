import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable weekday header row for calendar layouts.
class CalendarWeekdayHeader extends StatelessWidget {
  /// Creates a [CalendarWeekdayHeader] widget.
  const CalendarWeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.E(locale);
    // Standard 7 days starting from Monday (e.g. 2026-01-05 was Monday)
    final mondayBase = DateTime(2026, 1, 5);
    final weekDays = List.generate(7, (i) => mondayBase.add(Duration(days: i)));

    return Row(
      children: weekDays.map((d) {
        return Expanded(
          child: Center(
            child: Text(
              format.format(d),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
