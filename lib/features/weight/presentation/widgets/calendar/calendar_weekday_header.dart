import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable weekday header row for calendar layouts.
class CalendarWeekdayHeader extends StatelessWidget {
  /// Creates a [CalendarWeekdayHeader] widget.
  const CalendarWeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.EEEE(locale);
    // Standard 7 days starting from Monday (e.g. 2026-01-05 was Monday)
    final mondayBase = DateTime(2026, 1, 5);
    final weekDays = List.generate(7, (i) => mondayBase.add(Duration(days: i)));

    String capitalize3(String s) {
      if (s.length < 3) return s.toUpperCase();
      final sub = s.substring(0, 3);
      return sub[0].toUpperCase() + sub.substring(1);
    }

    return Row(
      children: weekDays.map((d) {
        return Expanded(
          child: Center(
            child: Text(
              capitalize3(format.format(d)),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
