// Abbreviated weekday labels spanning the calendar grid's first row.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders seven abbreviated weekday labels starting Monday, localized and
/// capitalized for the current locale.
class CalendarWeekdayHeader extends StatelessWidget {
  const CalendarWeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.EEEE(locale);
    // Standard 7 days starting from Monday (e.g. 2026-01-05 was Monday)
    final mondayBase = DateTime(2026, 1, 5);
    final weekDays = List.generate(7, (i) => mondayBase.add(Duration(days: i)));

    String capitalize3(String s) {
      // Capitalizes the first letter of a three-character abbreviation.
      if (s.length < 3) return s.toUpperCase();
      final sub = s.substring(0, 3);
      return sub[0].toUpperCase() + sub.substring(1);
    }

    return Row(
      children: weekDays.map((d) {
        final fullDayName = DateFormat.EEEE(locale).format(d);
        return Expanded(
          child: Center(
            child: Semantics(
              label: fullDayName,
              excludeSemantics: true,
              child: Text(
                capitalize3(format.format(d)),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
