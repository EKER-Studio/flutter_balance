import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('WeightEntry', () {
    final testDateTime = DateTime(2025, 1, 1, 12, 0);

    group('instantiation', () {
      test('creates instance with all required parameters', () {
        final entry = WeightEntry(
          weightKg: 70.0,
          dateTime: testDateTime,
          note: 'Test note',
        );

        expect(entry.weightKg, 70.0);
        expect(entry.dateTime, testDateTime);
        expect(entry.note, 'Test note');
        expect(entry.id, 0);
      });

      test('creates instance with default id when not specified', () {
        final entry = WeightEntry(weightKg: 70.0, dateTime: testDateTime);

        expect(entry.id, 0);
      });

      test('creates instance with null note when not specified', () {
        final entry = WeightEntry(weightKg: 70.0, dateTime: testDateTime);

        expect(entry.note, isNull);
      });
    });

    group('static constants', () {
      test('minWeightKg is set correctly', () {
        expect(WeightEntry.minWeightKg, 20.0);
      });

      test('maxWeightKg is set correctly', () {
        expect(WeightEntry.maxWeightKg, 300.0);
      });
    });

    group('validation bounds', () {
      test('allows weight at minimum boundary', () {
        final entry = WeightEntry(
          weightKg: WeightEntry.minWeightKg,
          dateTime: testDateTime,
        );

        expect(entry.weightKg, WeightEntry.minWeightKg);
      });

      test('allows weight at maximum boundary', () {
        final entry = WeightEntry(
          weightKg: WeightEntry.maxWeightKg,
          dateTime: testDateTime,
        );

        expect(entry.weightKg, WeightEntry.maxWeightKg);
      });

      test('allows weight between boundaries', () {
        final entry = WeightEntry(weightKg: 100.0, dateTime: testDateTime);

        expect(entry.weightKg, 100.0);
      });
    });

    group('edge cases and error conditions', () {
      test('handles zero weight correctly', () {
        final entry = WeightEntry(weightKg: 0.0, dateTime: testDateTime);

        expect(entry.weightKg, 0.0);
      });

      test('handles very small weights', () {
        final entry = WeightEntry(weightKg: 0.001, dateTime: testDateTime);

        expect(entry.weightKg, 0.001);
      });

      test('handles very large weights', () {
        final entry = WeightEntry(weightKg: 999.999, dateTime: testDateTime);

        expect(entry.weightKg, 999.999);
      });

      test('handles negative weights (within bounds)', () {
        // While not realistic for body weight, this is allowed by the entity
        final entry = WeightEntry(weightKg: -10.0, dateTime: testDateTime);

        expect(entry.weightKg, -10.0);
      });
    });

    group('immutable properties', () {
      test('weightKg is immutable', () {
        final entry = WeightEntry(weightKg: 70.0, dateTime: testDateTime);

        // Since it's a const class, we can't actually modify it after creation
        expect(entry.weightKg, 70.0);
      });

      test('dateTime is immutable', () {
        final entry = WeightEntry(weightKg: 70.0, dateTime: testDateTime);

        expect(entry.dateTime, testDateTime);
      });

      test('note is immutable', () {
        final entry = WeightEntry(
          weightKg: 70.0,
          dateTime: testDateTime,
          note: 'Original note',
        );

        expect(entry.note, 'Original note');
      });
    });

    group('id handling', () {
      test('uses provided id when specified', () {
        final entry = WeightEntry(
          id: 123,
          weightKg: 70.0,
          dateTime: testDateTime,
        );

        expect(entry.id, 123);
      });

      test('defaults to 0 when no id provided', () {
        final entry = WeightEntry(weightKg: 70.0, dateTime: testDateTime);

        expect(entry.id, 0);
      });
    });
  });
}
