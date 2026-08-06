import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/time_period.dart';

void main() {
  group('TimePeriodX.lookbackDuration', () {
    test('week looks back 7 days', () {
      expect(TimePeriod.week.lookbackDuration, const Duration(days: 7));
    });

    test('month looks back 30 days', () {
      expect(TimePeriod.month.lookbackDuration, const Duration(days: 30));
    });

    test('year looks back 365 days', () {
      expect(TimePeriod.year.lookbackDuration, const Duration(days: 365));
    });

    test('all looks back zero days', () {
      expect(TimePeriod.all.lookbackDuration, Duration.zero);
    });

    test('covers every enum value', () {
      expect(TimePeriod.values, hasLength(4));
    });
  });

  test('monthlyComplianceDays equals 30', () {
    expect(monthlyComplianceDays, 30);
  });
}
