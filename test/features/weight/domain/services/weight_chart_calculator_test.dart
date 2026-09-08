import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/services/weight_chart_calculator.dart';

void main() {
  group('WeightChartCalculator', () {
    final now = DateTime.now();

    group('filterAndAggregate', () {
      test('returns all entries aggregated by day when period is all', () {
        final entries = [
          WeightEntry(
            id: 1,
            weightKg: 80.0,
            dateTime: DateTime(2026, 5, 1, 8, 30),
          ),
          WeightEntry(
            id: 2,
            weightKg: 81.0,
            dateTime: DateTime(2026, 5, 1, 20, 0),
          ),
          WeightEntry(
            id: 3,
            weightKg: 79.5,
            dateTime: DateTime(2026, 5, 2, 9, 0),
          ),
        ];

        final result = WeightChartCalculator.filterAndAggregate(
          entries,
          TimePeriod.all,
        );

        expect(result.length, 2);
        // May 1: average of 80.0 and 81.0 = 80.5 at noon
        expect(result[0].id, 1);
        expect(result[0].weightKg, 80.5);
        expect(result[0].dateTime, DateTime(2026, 5, 1, 12, 0));

        // May 2: single entry 79.5 at noon
        expect(result[1].id, 3);
        expect(result[1].weightKg, 79.5);
        expect(result[1].dateTime, DateTime(2026, 5, 2, 12, 0));
      });

      test('filters out measurements older than period lookback duration', () {
        final recentEntry = WeightEntry(
          id: 1,
          weightKg: 75.0,
          dateTime: now.subtract(const Duration(days: 2)),
        );
        final oldEntry = WeightEntry(
          id: 2,
          weightKg: 76.0,
          dateTime: now.subtract(const Duration(days: 20)),
        );

        final resultWeek = WeightChartCalculator.filterAndAggregate([
          recentEntry,
          oldEntry,
        ], TimePeriod.week);

        expect(resultWeek.length, 1);
        expect(resultWeek.first.id, 1);

        final resultMonth = WeightChartCalculator.filterAndAggregate([
          recentEntry,
          oldEntry,
        ], TimePeriod.month);

        expect(resultMonth.length, 2);
      });

      test('handles empty input gracefully', () {
        final result = WeightChartCalculator.filterAndAggregate(
          [],
          TimePeriod.week,
        );
        expect(result, isEmpty);
      });
    });

    group('sameEntries', () {
      test('returns true for identical references', () {
        final list = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ];
        expect(WeightChartCalculator.sameEntries(list, list), isTrue);
      });

      test('returns false when memo is null or lengths differ', () {
        final list = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ];
        expect(WeightChartCalculator.sameEntries(list, null), isFalse);
        expect(WeightChartCalculator.sameEntries(list, []), isFalse);
      });

      test('returns true when entries match by id, weight, and date', () {
        final listA = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
          WeightEntry(id: 2, weightKg: 71.0, dateTime: DateTime(2026, 1, 2)),
        ];
        final listB = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
          WeightEntry(id: 2, weightKg: 71.0, dateTime: DateTime(2026, 1, 2)),
        ];
        expect(WeightChartCalculator.sameEntries(listA, listB), isTrue);
      });

      test('returns false when any property differs', () {
        final listA = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ];
        final diffWeight = [
          WeightEntry(id: 1, weightKg: 70.5, dateTime: DateTime(2026, 1, 1)),
        ];
        final diffDate = [
          WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 1, 2)),
        ];
        final diffId = [
          WeightEntry(id: 2, weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ];

        expect(WeightChartCalculator.sameEntries(listA, diffWeight), isFalse);
        expect(WeightChartCalculator.sameEntries(listA, diffDate), isFalse);
        expect(WeightChartCalculator.sameEntries(listA, diffId), isFalse);
      });
    });
  });
}
