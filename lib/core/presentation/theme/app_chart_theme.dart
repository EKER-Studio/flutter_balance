import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Reusable chart design tokens and styling helpers for `fl_chart`.
abstract final class AppChartTheme {
  /// Builds standard horizontal grid lines styled according to the active [ColorScheme].
  static FlGridData gridData({
    required ColorScheme colorScheme,
    required double horizontalInterval,
  }) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: horizontalInterval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          strokeWidth: 1,
          dashArray: const [4, 4],
        );
      },
    );
  }

  /// Builds a transparent border configuration omitting bounding box strokes.
  static FlBorderData borderData() {
    return FlBorderData(show: false);
  }

  /// Linear gradient for the main line stroke.
  static LinearGradient lineGradient(Color primaryColor) {
    return LinearGradient(
      colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
    );
  }

  /// Area fill gradient beneath the line chart.
  static LinearGradient belowBarGradient(Color primaryColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.28),
        primaryColor.withValues(alpha: 0.0),
      ],
    );
  }

  /// Computes the bottom title interval step based on entry list length and [period].
  static double bottomInterval(int length, TimePeriod period) {
    if (length <= 1) return 1;
    final targetIntervals = switch (period) {
      TimePeriod.week => 6,
      TimePeriod.month => 4,
      TimePeriod.year || TimePeriod.all => 5,
    };
    return math.max(1, ((length - 1) / targetIntervals).ceil()).toDouble();
  }

  /// Formats the bottom axis date label for the given [period].
  static String bottomAxisLabel(
    BuildContext context,
    DateTime date,
    TimePeriod period,
    AppLocalizations l10n,
  ) {
    return switch (period) {
      TimePeriod.week => weekdayLabel(date.weekday, l10n),
      TimePeriod.month => date.day.toString(),
      TimePeriod.year || TimePeriod.all => monthLabel(context, date),
    };
  }

  /// Formats a weekday number (1..7) into a localized short weekday string.
  static String weekdayLabel(int weekday, AppLocalizations l10n) {
    return switch (weekday) {
      DateTime.monday => l10n.weekdayShortMonday,
      DateTime.tuesday => l10n.weekdayShortTuesday,
      DateTime.wednesday => l10n.weekdayShortWednesday,
      DateTime.thursday => l10n.weekdayShortThursday,
      DateTime.friday => l10n.weekdayShortFriday,
      DateTime.saturday => l10n.weekdayShortSaturday,
      DateTime.sunday => l10n.weekdayShortSunday,
      _ => l10n.weekdayShortMonday,
    };
  }

  /// Formats a [DateTime] into a localized short month name.
  static String monthLabel(BuildContext context, DateTime date) =>
      DateFormat.MMM(Localizations.localeOf(context).toString()).format(date);

  /// Determines whether a year/all period tick is a duplicate of the previous rendered month.
  static bool isDuplicateMonthTick(
    int index,
    List<DateTime> dates,
    TimePeriod period,
  ) {
    if (period != TimePeriod.year && period != TimePeriod.all) return false;
    if (index <= 0 || index >= dates.length) return false;
    final current = dates[index];
    final prev = dates[index - 1];
    return current.month == prev.month && current.year == prev.year;
  }
}
