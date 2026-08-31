import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/services/period_comparison_calculator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('PeriodComparisonCalculator', () {
    test(
      'returns empty summaries and hasComparisonData=false when entries is empty',
      () {
        final result = PeriodComparisonCalculator.compareMonths(
          entries: [],
          now: DateTime(2026, 8, 15),
        );

        expect(result.hasComparisonData, isFalse);
        expect(result.currentPeriod.entryCount, 0);
        expect(result.previousPeriod.entryCount, 0);
        expect(result.deltaNetChange, isNull);
        expect(result.deltaAverage, isNull);
      },
    );

    test(
      'returns hasComparisonData=false when only current month has entries',
      () {
        final entries = [
          WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 8, 1)),
          WeightEntry(id: 2, weightKg: 79.0, dateTime: DateTime(2026, 8, 10)),
        ];

        final result = PeriodComparisonCalculator.compareMonths(
          entries: entries,
          now: DateTime(2026, 8, 15),
        );

        expect(result.hasComparisonData, isFalse);
        expect(result.currentPeriod.entryCount, 2);
        expect(result.currentPeriod.netChange, -1.0);
        expect(result.previousPeriod.entryCount, 0);
        expect(result.deltaNetChange, isNull);
      },
    );

    test('calculates deltas correctly when both months have entries', () {
      final entries = [
        // July entries (Previous month)
        WeightEntry(id: 1, weightKg: 82.0, dateTime: DateTime(2026, 7, 1)),
        WeightEntry(
          id: 2,
          weightKg: 81.0,
          dateTime: DateTime(2026, 7, 31),
        ), // Net: -1.0, Avg: 81.5, Count: 2
        // August entries (Current month)
        WeightEntry(id: 3, weightKg: 81.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(
          id: 4,
          weightKg: 79.0,
          dateTime: DateTime(2026, 8, 15),
        ), // Net: -2.0, Avg: 80.0, Count: 2
      ];

      final result = PeriodComparisonCalculator.compareMonths(
        entries: entries,
        now: DateTime(2026, 8, 20),
      );

      expect(result.hasComparisonData, isTrue);
      expect(result.currentPeriod.entryCount, 2);
      expect(result.currentPeriod.netChange, -2.0);
      expect(result.currentPeriod.averageWeight, 80.0);

      expect(result.previousPeriod.entryCount, 2);
      expect(result.previousPeriod.netChange, -1.0);
      expect(result.previousPeriod.averageWeight, 81.5);

      expect(
        result.deltaNetChange,
        -1.0,
      ); // -2.0 - (-1.0) = -1.0 kg (more weight lost)
      expect(result.deltaAverage, -1.5); // 80.0 - 81.5 = -1.5 kg
      expect(result.deltaEntryCount, 0);
    });

    test(
      'handles January reference date rolling over to December of previous year',
      () {
        final entries = [
          // December 2025
          WeightEntry(id: 1, weightKg: 85.0, dateTime: DateTime(2025, 12, 10)),
          // January 2026
          WeightEntry(id: 2, weightKg: 84.0, dateTime: DateTime(2026, 1, 5)),
        ];

        final result = PeriodComparisonCalculator.compareMonths(
          entries: entries,
          now: DateTime(2026, 1, 15),
        );

        expect(result.hasComparisonData, isTrue);
        expect(result.currentPeriod.entryCount, 1);
        expect(result.previousPeriod.entryCount, 1);
      },
    );
  });
}
