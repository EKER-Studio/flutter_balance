import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders seven abbreviated weekday labels starting with the configured first day,
/// localized and capitalized for the current locale.
class CalendarWeekdayHeader extends StatelessWidget {
  final FirstDayOfWeek firstDayOfWeek;

  const CalendarWeekdayHeader({super.key, required this.firstDayOfWeek});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.EEEE(locale);

    // 2026-01-05 is Monday, 2026-01-04 is Sunday.
    DateTime baseDay;
    switch (firstDayOfWeek) {
      case FirstDayOfWeek.monday:
        baseDay = DateTime(2026, 1, 5); // Monday
      case FirstDayOfWeek.sunday:
        baseDay = DateTime(2026, 1, 4); // Sunday
      case FirstDayOfWeek.system:
        final systemFirstDayIndex = MaterialLocalizations.of(
          context,
        ).firstDayOfWeekIndex;
        if (systemFirstDayIndex == 1) {
          baseDay = DateTime(2026, 1, 5);
        } else {
          baseDay = DateTime(2026, 1, 4);
        }
    }

    final weekDays = List.generate(7, (i) => baseDay.add(Duration(days: i)));

    String capitalize3(String s) {
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
