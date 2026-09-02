import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Pure domain service calculating logging habit statistics such as current streak, best streak, and total logging compliance.
class HabitsCalculator {
  const HabitsCalculator._();

  /// Calculates the current consecutive days logging streak relative to [now].
  ///
  /// @param entries The list of historical weight entries.
  /// @param now The reference timestamp (defaults to current system time if null).
  static int calculateStreak(List<WeightEntry> entries, [DateTime? now]) {
    if (entries.isEmpty) return 0;

    final referenceDate = now ?? DateTime.now();
    final dates = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet();

    final todayDate = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayDate) ? todayDate : yesterdayDate;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculates the best historical consecutive days logging streak.
  ///
  /// @param entries The list of historical weight entries.
  static int calculateBestStreak(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;

    final dates =
        entries
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

    int best = 1;
    int current = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return best;
  }

  /// Calculates the percentage of days logged out of total elapsed days since the first entry.
  ///
  /// @param entries The list of historical weight entries.
  /// @param now The reference timestamp (defaults to current system time if null).
  static int calculateTotalCompliance(
    List<WeightEntry> entries, [
    DateTime? now,
  ]) {
    if (entries.isEmpty) return 0;

    final referenceDate = now ?? DateTime.now();
    final firstDate = entries
        .map((e) => e.dateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);

    int totalDays = today.difference(start).inDays + 1;
    if (totalDays <= 0) totalDays = 1;

    final loggedDays = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;
    return ((loggedDays / totalDays) * 100).round().clamp(0, 100);
  }
}
