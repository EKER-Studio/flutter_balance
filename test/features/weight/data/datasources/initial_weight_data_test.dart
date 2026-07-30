import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/features/weight/data/datasources/initial_weight_data.dart';

void main() {
  group('initial_weight_data', () {
    test('getInitial3MonthsWeightEntries returns entries covering 90 days', () {
      final now = DateTime(2026, 7, 30, 10, 0);
      final entries = getInitial3MonthsWeightEntries(referenceDate: now);

      expect(entries, isNotEmpty);

      final dates = entries.map((e) => e.dateTime).toList()..sort();
      final earliest = dates.first;
      final latest = dates.last;
      final earliestDate = DateTime(
        earliest.year,
        earliest.month,
        earliest.day,
      );
      final latestDate = DateTime(latest.year, latest.month, latest.day);
      expect(latestDate.difference(earliestDate).inDays, equals(90));
    });

    test(
      'getInitial3MonthsWeightEntries contains days with multiple intraday measurements',
      () {
        final now = DateTime(2026, 7, 30, 10, 0);
        final entries = getInitial3MonthsWeightEntries(referenceDate: now);

        final Map<String, int> dailyCounts = {};
        for (final entry in entries) {
          final key =
              '${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}';
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        }

        final daysWithMultipleEntries = dailyCounts.values.where(
          (count) => count > 1,
        );
        expect(daysWithMultipleEntries, isNotEmpty);
        expect(daysWithMultipleEntries.length, greaterThan(10));
      },
    );
  });
}
