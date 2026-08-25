import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';

void main() {
  group('BmiCategory.fromBmi — WHO cut-offs (lower-inclusive)', () {
    test('returns underweight for bmi < 18.5', () {
      expect(BmiCategory.fromBmi(0), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.4), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.49), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(18.499), BmiCategory.underweight);
    });

    test('returns normal for 18.5 <= bmi < 25.0 (boundary inclusive)', () {
      expect(BmiCategory.fromBmi(18.5), BmiCategory.normal);
      expect(BmiCategory.fromBmi(18.5001), BmiCategory.normal);
      expect(BmiCategory.fromBmi(24.9), BmiCategory.normal);
      expect(BmiCategory.fromBmi(24.99), BmiCategory.normal);
    });

    test('returns overweight for 25.0 <= bmi < 30.0', () {
      expect(BmiCategory.fromBmi(25.0), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(27.5), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(29.9), BmiCategory.overweight);
      expect(BmiCategory.fromBmi(29.999), BmiCategory.overweight);
    });

    test('returns obeseClass1 for 30.0 <= bmi < 35.0', () {
      expect(BmiCategory.fromBmi(30.0), BmiCategory.obeseClass1);
      expect(BmiCategory.fromBmi(32.5), BmiCategory.obeseClass1);
      expect(BmiCategory.fromBmi(34.9), BmiCategory.obeseClass1);
      expect(BmiCategory.fromBmi(34.999), BmiCategory.obeseClass1);
    });

    test('returns obeseClass2 for 35.0 <= bmi < 40.0', () {
      expect(BmiCategory.fromBmi(35.0), BmiCategory.obeseClass2);
      expect(BmiCategory.fromBmi(37.5), BmiCategory.obeseClass2);
      expect(BmiCategory.fromBmi(39.9), BmiCategory.obeseClass2);
      expect(BmiCategory.fromBmi(39.999), BmiCategory.obeseClass2);
    });

    test('returns obeseClass3 for bmi >= 40.0', () {
      expect(BmiCategory.fromBmi(40.0), BmiCategory.obeseClass3);
      expect(BmiCategory.fromBmi(40.001), BmiCategory.obeseClass3);
      expect(BmiCategory.fromBmi(45), BmiCategory.obeseClass3);
      expect(BmiCategory.fromBmi(100), BmiCategory.obeseClass3);
    });

    test('handles negative and zero edge cases as underweight', () {
      expect(BmiCategory.fromBmi(-5), BmiCategory.underweight);
      expect(BmiCategory.fromBmi(0), BmiCategory.underweight);
    });

    test('contains all six WHO categories', () {
      expect(BmiCategory.values, [
        BmiCategory.underweight,
        BmiCategory.normal,
        BmiCategory.overweight,
        BmiCategory.obeseClass1,
        BmiCategory.obeseClass2,
        BmiCategory.obeseClass3,
      ]);
    });
  });
}
