import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/services/bmi_calculator.dart';

void main() {
  group('BmiCalculator', () {
    group('calculate', () {
      test('computes correct BMI for standard values', () {
        // 70kg / (1.75m * 1.75m) = 22.857...
        final bmi = BmiCalculator.calculate(weightKg: 70.0, heightCm: 175.0);
        expect(bmi, closeTo(22.86, 0.01));
      });

      test('returns 0.0 when weight is 0 or negative', () {
        expect(
          BmiCalculator.calculate(weightKg: 0.0, heightCm: 175.0),
          equals(0.0),
        );
        expect(
          BmiCalculator.calculate(weightKg: -5.0, heightCm: 175.0),
          equals(0.0),
        );
      });

      test('returns 0.0 when height is 0 or negative', () {
        expect(
          BmiCalculator.calculate(weightKg: 70.0, heightCm: 0.0),
          equals(0.0),
        );
        expect(
          BmiCalculator.calculate(weightKg: 70.0, heightCm: -170.0),
          equals(0.0),
        );
      });

      test('computes boundary values correctly without throwing', () {
        expect(
          () => BmiCalculator.calculate(weightKg: 100.0, heightCm: 200.0),
          returnsNormally,
        );
        final bmi = BmiCalculator.calculate(weightKg: 100.0, heightCm: 200.0);
        expect(bmi, closeTo(25.0, 0.01));
      });
    });

    group('categoryFor', () {
      test('resolves underweight below 18.5', () {
        expect(BmiCalculator.categoryFor(bmi: 18.49), BmiCategory.underweight);
      });

      test('resolves normal from 18.5 to 24.9', () {
        expect(BmiCalculator.categoryFor(bmi: 18.5), BmiCategory.normal);
        expect(BmiCalculator.categoryFor(bmi: 24.9), BmiCategory.normal);
      });

      test('resolves overweight from 25.0 to 29.9', () {
        expect(BmiCalculator.categoryFor(bmi: 25.0), BmiCategory.overweight);
        expect(BmiCalculator.categoryFor(bmi: 29.9), BmiCategory.overweight);
      });

      test('resolves obesity classes', () {
        expect(BmiCalculator.categoryFor(bmi: 30.0), BmiCategory.obeseClass1);
        expect(BmiCalculator.categoryFor(bmi: 35.0), BmiCategory.obeseClass2);
        expect(BmiCalculator.categoryFor(bmi: 40.0), BmiCategory.obeseClass3);
      });
    });

    group('categoryForMeasurements', () {
      test('calculates and resolves category directly', () {
        expect(
          BmiCalculator.categoryForMeasurements(
            weightKg: 70.0,
            heightCm: 175.0,
          ),
          BmiCategory.normal,
        );
        expect(
          BmiCalculator.categoryForMeasurements(
            weightKg: 95.0,
            heightCm: 175.0,
          ),
          BmiCategory.obeseClass1,
        );
      });
    });
  });
}
