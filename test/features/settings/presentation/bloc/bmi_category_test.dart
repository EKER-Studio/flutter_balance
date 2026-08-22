import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';

void main() {
  group('BmiCategory', () {
    test('contains all expected WHO categories', () {
      expect(
        BmiCategory.values,
        equals([
          BmiCategory.underweight,
          BmiCategory.normal,
          BmiCategory.overweight,
          BmiCategory.obese,
        ]),
      );
    });

    group('fromBmi', () {
      test('categorizes underweight correctly for values < 18.5', () {
        expect(BmiCategory.fromBmi(0.0), equals(BmiCategory.underweight));
        expect(BmiCategory.fromBmi(15.2), equals(BmiCategory.underweight));
        expect(BmiCategory.fromBmi(18.4), equals(BmiCategory.underweight));
        expect(BmiCategory.fromBmi(18.499), equals(BmiCategory.underweight));
      });

      test('categorizes normal correctly for values >= 18.5 and < 25.0', () {
        expect(BmiCategory.fromBmi(18.5), equals(BmiCategory.normal));
        expect(BmiCategory.fromBmi(21.7), equals(BmiCategory.normal));
        expect(BmiCategory.fromBmi(24.9), equals(BmiCategory.normal));
        expect(BmiCategory.fromBmi(24.999), equals(BmiCategory.normal));
      });

      test(
        'categorizes overweight correctly for values >= 25.0 and < 30.0',
        () {
          expect(BmiCategory.fromBmi(25.0), equals(BmiCategory.overweight));
          expect(BmiCategory.fromBmi(27.4), equals(BmiCategory.overweight));
          expect(BmiCategory.fromBmi(29.9), equals(BmiCategory.overweight));
          expect(BmiCategory.fromBmi(29.999), equals(BmiCategory.overweight));
        },
      );

      test('categorizes obese correctly for values >= 30.0', () {
        expect(BmiCategory.fromBmi(30.0), equals(BmiCategory.obese));
        expect(BmiCategory.fromBmi(32.5), equals(BmiCategory.obese));
        expect(BmiCategory.fromBmi(45.0), equals(BmiCategory.obese));
        expect(BmiCategory.fromBmi(100.0), equals(BmiCategory.obese));
      });
    });
  });
}
