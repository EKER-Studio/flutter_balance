import 'package:intl/intl.dart';
import 'package:balance/features/statistics/domain/entities/period_comparison.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A service computing comparative metrics between adjacent calendar months.
class PeriodComparisonCalculator {
  const PeriodComparisonCalculator._();

  /// Compares metrics between the last [days] window and the previous [days] window.
  ///
  /// For example, if [days] is 7 and [now] is Sep 1, the current window is
  /// Aug 26 – Sep 1 (7 days), and the previous window is Aug 19 – Aug 25 (7 days).
  ///
  /// @param entries The full list of weight measurements.
  /// @param days The size of the rolling window in days (default 7).
  /// @param now The reference timestamp (defaults to `DateTime.now()`).
  /// @param locale The locale tag used for formatting labels.
  /// @return A [PeriodComparisonResult] with aggregated delta metrics.
  static PeriodComparisonResult compareRollingDays({
    required List<WeightEntry> entries,
    int days = 7,
    DateTime? now,
    String? locale,
  }) {
    final referenceDate = now ?? DateTime.now();
    final endOfCurrent = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      23,
      59,
      59,
      999,
    );
    final startOfCurrent = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    ).subtract(Duration(days: days - 1));

    final endOfPrevious = startOfCurrent.subtract(
      const Duration(milliseconds: 1),
    );
    final startOfPrevious = DateTime(
      startOfCurrent.year,
      startOfCurrent.month,
      startOfCurrent.day,
    ).subtract(Duration(days: days));

    final currentEntries =
        entries
            .where(
              (e) =>
                  !e.dateTime.isBefore(startOfCurrent) &&
                  !e.dateTime.isAfter(endOfCurrent),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final previousEntries =
        entries
            .where(
              (e) =>
                  !e.dateTime.isBefore(startOfPrevious) &&
                  !e.dateTime.isAfter(endOfPrevious),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final currentDateFormat = DateFormat('d MMM', locale);
    final currentLabel =
        '${currentDateFormat.format(startOfCurrent)} – ${currentDateFormat.format(endOfCurrent)}';
    final previousLabel =
        '${currentDateFormat.format(startOfPrevious)} – ${currentDateFormat.format(endOfPrevious)}';

    final currentSummary = _summarize(
      entries: currentEntries,
      label: currentLabel,
    );

    final previousSummary = _summarize(
      entries: previousEntries,
      label: previousLabel,
    );

    final hasComparisonData =
        currentEntries.isNotEmpty && previousEntries.isNotEmpty;

    final deltaNetChange =
        (currentSummary.netChange != null && previousSummary.netChange != null)
        ? currentSummary.netChange! - previousSummary.netChange!
        : null;

    final deltaAverage =
        (currentSummary.averageWeight != null &&
            previousSummary.averageWeight != null)
        ? currentSummary.averageWeight! - previousSummary.averageWeight!
        : null;

    final deltaEntryCount =
        currentSummary.entryCount - previousSummary.entryCount;

    return PeriodComparisonResult(
      currentPeriod: currentSummary,
      previousPeriod: previousSummary,
      deltaNetChange: deltaNetChange,
      deltaAverage: deltaAverage,
      deltaEntryCount: deltaEntryCount,
      hasComparisonData: hasComparisonData,
    );
  }

  /// Compares metrics between the current month and the immediately preceding month.
  ///
  /// @param entries The full list of weight measurements.
  /// @param now The reference timestamp (defaults to `DateTime.now()`).
  /// @param locale The locale tag used for formatting month names.
  /// @return A [PeriodComparisonResult] with aggregated delta metrics.
  static PeriodComparisonResult compareMonths({
    required List<WeightEntry> entries,
    DateTime? now,
    String? locale,
  }) {
    final referenceDate = now ?? DateTime.now();
    final currentYear = referenceDate.year;
    final currentMonth = referenceDate.month;

    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;

    final currentEntries =
        entries
            .where(
              (e) =>
                  e.dateTime.year == currentYear &&
                  e.dateTime.month == currentMonth,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final previousEntries =
        entries
            .where(
              (e) =>
                  e.dateTime.year == prevYear && e.dateTime.month == prevMonth,
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final currentSummary = _summarize(
      entries: currentEntries,
      label: DateFormat.MMMM(
        locale,
      ).format(DateTime(currentYear, currentMonth)),
    );

    final previousSummary = _summarize(
      entries: previousEntries,
      label: DateFormat.MMMM(locale).format(DateTime(prevYear, prevMonth)),
    );

    final hasComparisonData =
        currentEntries.isNotEmpty && previousEntries.isNotEmpty;

    final deltaNetChange =
        (currentSummary.netChange != null && previousSummary.netChange != null)
        ? currentSummary.netChange! - previousSummary.netChange!
        : null;

    final deltaAverage =
        (currentSummary.averageWeight != null &&
            previousSummary.averageWeight != null)
        ? currentSummary.averageWeight! - previousSummary.averageWeight!
        : null;

    final deltaEntryCount =
        currentSummary.entryCount - previousSummary.entryCount;

    return PeriodComparisonResult(
      currentPeriod: currentSummary,
      previousPeriod: previousSummary,
      deltaNetChange: deltaNetChange,
      deltaAverage: deltaAverage,
      deltaEntryCount: deltaEntryCount,
      hasComparisonData: hasComparisonData,
    );
  }

  static PeriodSummary _summarize({
    required List<WeightEntry> entries,
    required String label,
  }) {
    if (entries.isEmpty) {
      return PeriodSummary(
        startWeight: null,
        endWeight: null,
        netChange: null,
        averageWeight: null,
        entryCount: 0,
        label: label,
      );
    }

    final startWeight = entries.first.weightKg;
    final endWeight = entries.last.weightKg;
    final netChange = entries.length >= 2 ? endWeight - startWeight : 0.0;
    final totalWeight = entries.map((e) => e.weightKg).reduce((a, b) => a + b);
    final averageWeight = totalWeight / entries.length;

    return PeriodSummary(
      startWeight: startWeight,
      endWeight: endWeight,
      netChange: netChange,
      averageWeight: averageWeight,
      entryCount: entries.length,
      label: label,
    );
  }
}
