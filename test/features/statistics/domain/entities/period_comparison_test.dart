import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/period_comparison.dart';

void main() {
  group('PeriodSummary & PeriodComparisonResult Tests', () {
    test('PeriodSummary initializes with correct values', () {
      const summary = PeriodSummary(
        startWeight: 80.0,
        endWeight: 78.5,
        netChange: -1.5,
        averageWeight: 79.2,
        entryCount: 15,
        label: 'August',
      );

      expect(summary.startWeight, 80.0);
      expect(summary.endWeight, 78.5);
      expect(summary.netChange, -1.5);
      expect(summary.averageWeight, 79.2);
      expect(summary.entryCount, 15);
      expect(summary.label, 'August');
    });

    test('PeriodComparisonResult initializes with comparative metrics', () {
      const current = PeriodSummary(
        startWeight: 79.0,
        endWeight: 77.0,
        netChange: -2.0,
        averageWeight: 78.0,
        entryCount: 20,
        label: 'August',
      );

      const previous = PeriodSummary(
        startWeight: 81.0,
        endWeight: 79.0,
        netChange: -2.0,
        averageWeight: 80.0,
        entryCount: 18,
        label: 'July',
      );

      const result = PeriodComparisonResult(
        currentPeriod: current,
        previousPeriod: previous,
        deltaNetChange: 0.0,
        deltaAverage: -2.0,
        deltaEntryCount: 2,
        hasComparisonData: true,
      );

      expect(result.currentPeriod, current);
      expect(result.previousPeriod, previous);
      expect(result.deltaNetChange, 0.0);
      expect(result.deltaAverage, -2.0);
      expect(result.deltaEntryCount, 2);
      expect(result.hasComparisonData, isTrue);
    });

    test('PeriodComparisonResult handles null metrics when data is insufficient', () {
      const current = PeriodSummary(
        startWeight: null,
        endWeight: null,
        netChange: null,
        averageWeight: null,
        entryCount: 0,
        label: 'Current',
      );

      const previous = PeriodSummary(
        startWeight: null,
        endWeight: null,
        netChange: null,
        averageWeight: null,
        entryCount: 0,
        label: 'Previous',
      );

      const result = PeriodComparisonResult(
        currentPeriod: current,
        previousPeriod: previous,
        deltaNetChange: null,
        deltaAverage: null,
        deltaEntryCount: 0,
        hasComparisonData: false,
      );

      expect(result.hasComparisonData, isFalse);
      expect(result.deltaNetChange, isNull);
      expect(result.deltaAverage, isNull);
    });
  });
}
