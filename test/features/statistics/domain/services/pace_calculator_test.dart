import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/services/pace_calculator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('PaceCalculator', () {
    final now = DateTime(2026, 9, 2, 12, 0);

    WeightEntry makeEntry(DateTime dt, double weight) {
      return WeightEntry(
        id: dt.millisecondsSinceEpoch,
        weightKg: weight,
        dateTime: dt,
      );
    }

    group('calculateWeeklyPace', () {
      test('returns null for empty list', () {
        expect(PaceCalculator.calculateWeeklyPace([], now: now), isNull);
      });

      test('returns null for single entry', () {
        final entries = [makeEntry(DateTime(2026, 9, 1), 70.0)];
        expect(PaceCalculator.calculateWeeklyPace(entries, now: now), isNull);
      });

      test('calculates correct weekly loss for 2 entries 7 days apart', () {
        final entries = [
          makeEntry(DateTime(2026, 8, 26), 75.0),
          makeEntry(DateTime(2026, 9, 2), 74.0),
        ];
        // Lost 1.0 kg over 7 days = -1.0 kg/week
        final pace = PaceCalculator.calculateWeeklyPace(entries, now: now);
        expect(pace, isNotNull);
        expect(pace!, closeTo(-1.0, 0.001));
      });

      test('calculates correct weekly gain for 2 entries 14 days apart', () {
        final entries = [
          makeEntry(DateTime(2026, 8, 19), 70.0),
          makeEntry(DateTime(2026, 9, 2), 72.0),
        ];
        // Gained 2.0 kg over 14 days (2 weeks) = +1.0 kg/week
        final pace = PaceCalculator.calculateWeeklyPace(entries, now: now);
        expect(pace, isNotNull);
        expect(pace!, closeTo(1.0, 0.001));
      });

      test('filters out entries outside the lookback window', () {
        final entries = [
          // 40 days ago (outside 30-day window)
          makeEntry(DateTime(2026, 7, 24), 80.0),
          // 14 days ago (inside window)
          makeEntry(DateTime(2026, 8, 19), 72.0),
          // Today (inside window)
          makeEntry(DateTime(2026, 9, 2), 71.0),
        ];
        // Inside window: 72.0 -> 71.0 over 14 days = -0.5 kg/week
        final pace = PaceCalculator.calculateWeeklyPace(
          entries,
          windowDays: 30,
          now: now,
        );
        expect(pace, isNotNull);
        expect(pace!, closeTo(-0.5, 0.001));
      });

      test(
        'returns null when only 1 entry falls inside the lookback window',
        () {
          final entries = [
            // 40 days ago (outside window)
            makeEntry(DateTime(2026, 7, 24), 80.0),
            // Today (inside window)
            makeEntry(DateTime(2026, 9, 2), 71.0),
          ];
          final pace = PaceCalculator.calculateWeeklyPace(
            entries,
            windowDays: 30,
            now: now,
          );
          expect(pace, isNull);
        },
      );

      test('returns 0.0 when entries occur on the exact same day', () {
        final entries = [
          makeEntry(DateTime(2026, 9, 2, 8, 0), 71.0),
          makeEntry(DateTime(2026, 9, 2, 20, 0), 71.5),
        ];
        final pace = PaceCalculator.calculateWeeklyPace(entries, now: now);
        expect(pace, 0.0);
      });
    });
  });
}
