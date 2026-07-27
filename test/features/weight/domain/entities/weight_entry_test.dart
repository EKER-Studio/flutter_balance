import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('WeightEntry', () {
    group('calculateBmi', () {
      test('returns correct BMI for normal weight', () {
        final bmi = WeightEntry.calculateBmi(70, 1.75);
        expect(bmi, closeTo(22.86, 0.01));
      });

      test('returns correct BMI for underweight', () {
        final bmi = WeightEntry.calculateBmi(50, 1.75);
        expect(bmi, closeTo(16.33, 0.01));
      });

      test('returns correct BMI for obese', () {
        final bmi = WeightEntry.calculateBmi(100, 1.75);
        expect(bmi, closeTo(32.65, 0.01));
      });

      test('works with zero height returns infinity', () {
        final bmi = WeightEntry.calculateBmi(70, 0);
        expect(bmi, double.infinity);
      });
    });
  });
}
