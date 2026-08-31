import 'package:intl/intl.dart';
import 'package:balance/features/statistics/domain/entities/period_comparison.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A service computing comparative metrics between adjacent calendar months.
class PeriodComparisonCalculator {
  const PeriodComparisonCalculator._();

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
