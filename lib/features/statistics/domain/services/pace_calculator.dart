import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Pure domain service calculating rate-of-change and pace metrics over historical weight entries.
class PaceCalculator {
  const PaceCalculator._();

  /// Computes the average weekly pace (weight change in kg per 7 days) over the given [windowDays].
  ///
  /// Filters entries within `[now - windowDays, now]`.
  /// Returns `null` if fewer than 2 entries exist in that window.
  ///
  /// @param entries The list of historical weight entries.
  /// @param windowDays The lookback window in days (defaults to 30).
  /// @param now The reference timestamp (defaults to current system time if null).
  static double? calculateWeeklyPace(
    List<WeightEntry> entries, {
    int windowDays = 30,
    DateTime? now,
  }) {
    if (entries.length < 2) return null;

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final referenceDate = now ?? DateTime.now();
    final windowStart = referenceDate.subtract(Duration(days: windowDays));

    final recentEntries = sorted
        .where((e) => !e.dateTime.isBefore(windowStart))
        .toList();
    if (recentEntries.length < 2) return null;

    final first = recentEntries.first;
    final last = recentEntries.last;

    final days = last.dateTime.difference(first.dateTime).inDays;
    if (days < 1) return 0.0;

    final weeks = days / 7.0;
    final diffKg = last.weightKg - first.weightKg;

    return diffKg / weeks;
  }
}
