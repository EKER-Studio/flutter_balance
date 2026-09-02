import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/services/habits_calculator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('HabitsCalculator', () {
    final now = DateTime(2026, 9, 2, 12, 0);

    WeightEntry makeEntry(DateTime dt, [double weight = 70.0]) {
      return WeightEntry(
        id: dt.millisecondsSinceEpoch,
        weightKg: weight,
        dateTime: dt,
      );
    }

    group('calculateStreak', () {
      test('returns 0 for empty list', () {
        expect(HabitsCalculator.calculateStreak([], now), 0);
      });

      test('returns 1 when only logged today', () {
        final entries = [makeEntry(DateTime(2026, 9, 2, 8, 0))];
        expect(HabitsCalculator.calculateStreak(entries, now), 1);
      });

      test('returns 1 when only logged yesterday', () {
        final entries = [makeEntry(DateTime(2026, 9, 1, 18, 0))];
        expect(HabitsCalculator.calculateStreak(entries, now), 1);
      });

      test('returns 0 when last log was 2 days ago', () {
        final entries = [makeEntry(DateTime(2026, 8, 31, 10, 0))];
        expect(HabitsCalculator.calculateStreak(entries, now), 0);
      });

      test('counts consecutive days starting today', () {
        final entries = [
          makeEntry(DateTime(2026, 9, 2, 8, 0)),
          makeEntry(DateTime(2026, 9, 1, 8, 0)),
          makeEntry(DateTime(2026, 8, 31, 8, 0)),
          makeEntry(DateTime(2026, 8, 30, 8, 0)),
        ];
        expect(HabitsCalculator.calculateStreak(entries, now), 4);
      });

      test('counts consecutive days starting yesterday', () {
        final entries = [
          makeEntry(DateTime(2026, 9, 1, 8, 0)),
          makeEntry(DateTime(2026, 8, 31, 8, 0)),
          makeEntry(DateTime(2026, 8, 30, 8, 0)),
        ];
        expect(HabitsCalculator.calculateStreak(entries, now), 3);
      });

      test('stops at the first gap', () {
        final entries = [
          makeEntry(DateTime(2026, 9, 2, 8, 0)),
          makeEntry(DateTime(2026, 9, 1, 8, 0)),
          // 8-31 missing
          makeEntry(DateTime(2026, 8, 30, 8, 0)),
          makeEntry(DateTime(2026, 8, 29, 8, 0)),
        ];
        expect(HabitsCalculator.calculateStreak(entries, now), 2);
      });

      test(
        'handles multiple entries on the same day without duplicating count',
        () {
          final entries = [
            makeEntry(DateTime(2026, 9, 2, 8, 0)),
            makeEntry(DateTime(2026, 9, 2, 20, 0)),
            makeEntry(DateTime(2026, 9, 1, 9, 0)),
            makeEntry(DateTime(2026, 9, 1, 19, 0)),
          ];
          expect(HabitsCalculator.calculateStreak(entries, now), 2);
        },
      );
    });

    group('calculateBestStreak', () {
      test('returns 0 for empty list', () {
        expect(HabitsCalculator.calculateBestStreak([]), 0);
      });

      test('returns 1 for single entry', () {
        final entries = [makeEntry(DateTime(2026, 9, 1))];
        expect(HabitsCalculator.calculateBestStreak(entries), 1);
      });

      test('returns 3 for 3 consecutive days', () {
        final entries = [
          makeEntry(DateTime(2026, 9, 1)),
          makeEntry(DateTime(2026, 9, 2)),
          makeEntry(DateTime(2026, 9, 3)),
        ];
        expect(HabitsCalculator.calculateBestStreak(entries), 3);
      });

      test('correctly identifies longest streak among multiple segments', () {
        final entries = [
          // Streak of 2
          makeEntry(DateTime(2026, 8, 1)),
          makeEntry(DateTime(2026, 8, 2)),
          // Gap
          // Streak of 4
          makeEntry(DateTime(2026, 8, 10)),
          makeEntry(DateTime(2026, 8, 11)),
          makeEntry(DateTime(2026, 8, 12)),
          makeEntry(DateTime(2026, 8, 13)),
          // Gap
          // Streak of 3
          makeEntry(DateTime(2026, 8, 20)),
          makeEntry(DateTime(2026, 8, 21)),
          makeEntry(DateTime(2026, 8, 22)),
        ];
        expect(HabitsCalculator.calculateBestStreak(entries), 4);
      });
    });

    group('calculateTotalCompliance', () {
      test('returns 0 for empty list', () {
        expect(HabitsCalculator.calculateTotalCompliance([], now), 0);
      });

      test('returns 100 for single entry logged today', () {
        final entries = [makeEntry(DateTime(2026, 9, 2))];
        expect(HabitsCalculator.calculateTotalCompliance(entries, now), 100);
      });

      test('calculates correct percentage for 5 days out of 10 elapsed', () {
        // Start date: 10 days ago (2026-08-24), today is 2026-09-02 (10 days total)
        final entries = [
          makeEntry(DateTime(2026, 8, 24)),
          makeEntry(DateTime(2026, 8, 26)),
          makeEntry(DateTime(2026, 8, 28)),
          makeEntry(DateTime(2026, 8, 30)),
          makeEntry(DateTime(2026, 9, 2)),
        ];
        // 5 unique days / 10 total days * 100 = 50%
        expect(HabitsCalculator.calculateTotalCompliance(entries, now), 50);
      });
    });
  });
}
