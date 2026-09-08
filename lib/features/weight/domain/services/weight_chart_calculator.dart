import 'package:balance/core/models/time_period.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Pure domain service for filtering and aggregating weight entries for chart display.
///
/// Keeps chart-specific transformations out of [WeightBloc] so the BLoC remains
/// an orchestrator and the logic is independently testable.
abstract final class WeightChartCalculator {
  /// Filters [entries] by [period] and collapses multiple measurements on the
  /// same calendar day into a single averaged point at noon.
  static List<WeightEntry> filterAndAggregate(
    List<WeightEntry> entries,
    TimePeriod period,
  ) {
    final filtered = switch (period) {
      TimePeriod.all => entries,
      TimePeriod.week || TimePeriod.month || TimePeriod.year =>
        entries
            .where(
              (e) => e.dateTime.isAfter(
                DateTime.now().subtract(period.lookbackDuration),
              ),
            )
            .toList(),
    };
    return _aggregateByDay(filtered);
  }

  /// Collapses multiple measurements on the same calendar day into one averaged entry.
  static List<WeightEntry> _aggregateByDay(List<WeightEntry> entries) {
    final Map<DateTime, List<WeightEntry>> grouped = {};
    for (final e in entries) {
      final dayKey = DateTime(
        e.dateTime.year,
        e.dateTime.month,
        e.dateTime.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(e);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((dayKey) {
      final dayEntries = grouped[dayKey]!;
      final avgWeight =
          dayEntries.map((e) => e.weightKg).reduce((a, b) => a + b) /
          dayEntries.length;
      final noonDate = DateTime(dayKey.year, dayKey.month, dayKey.day, 12);
      return WeightEntry(
        id: dayEntries.first.id,
        weightKg: (avgWeight * 100).round() / 100,
        dateTime: noonDate,
      );
    }).toList();
  }

  /// Compares two entry lists by content key without relying on identity.
  static bool sameEntries(List<WeightEntry> entries, List<WeightEntry>? memo) {
    if (identical(entries, memo)) return true;
    if (memo == null || entries.length != memo.length) return false;
    for (var i = 0; i < entries.length; i++) {
      final current = entries[i];
      final cached = memo[i];
      if (current.id != cached.id ||
          current.dateTime != cached.dateTime ||
          current.weightKg != cached.weightKg) {
        return false;
      }
    }
    return true;
  }
}
