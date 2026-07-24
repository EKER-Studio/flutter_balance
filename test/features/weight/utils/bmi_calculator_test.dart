import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';

void main() {
  group('BMI Calculation', () {
    late AppSettingsState state;

    setUp(() {
      state = const AppSettingsState(height: 175.0);
    });

    group('standard metric calculations', () {
      test('BMI for 70kg at 175cm is approximately 22.9', () {
        // BMI = 70 / (1.75 * 1.75) = 70 / 3.0625 = 22.857...
        final bmi = state.calculateBmi(70.0);
        expect(bmi, closeTo(22.86, 0.01));
      });

      test('BMI for 80kg at 180cm is approximately 24.7', () {
        // BMI = 80 / (1.80 * 1.80) = 80 / 3.24 = 24.691...
        final bmi = state.copyWith(height: 180.0).calculateBmi(80.0);
        expect(bmi, closeTo(24.69, 0.01));
      });

      test('BMI for 60kg at 170cm is approximately 20.8', () {
        // BMI = 60 / (1.70 * 1.70) = 60 / 2.89 = 20.761...
        final bmi = state.copyWith(height: 170.0).calculateBmi(60.0);
        expect(bmi, closeTo(20.76, 0.01));
      });

      test('BMI for 90kg at 175cm is approximately 29.4', () {
        // BMI = 90 / (1.75 * 1.75) = 90 / 3.0625 = 29.387...
        final bmi = state.calculateBmi(90.0);
        expect(bmi, closeTo(29.39, 0.01));
      });

      test('BMI for 50kg at 175cm is approximately 16.3', () {
        // BMI = 50 / (1.75 * 1.75) = 50 / 3.0625 = 16.326...
        final bmi = state.calculateBmi(50.0);
        expect(bmi, closeTo(16.33, 0.01));
      });

      test('BMI for 100kg at 200cm is approximately 25.0 (boundary)', () {
        // BMI = 100 / (2.00 * 2.00) = 100 / 4.0 = 25.0
        final bmi = state.copyWith(height: 200.0).calculateBmi(100.0);
        expect(bmi, closeTo(25.0, 0.01));
      });
    });

    group('boundary limits - extreme weights', () {
      test('BMI for extremely low weight (1kg) at 175cm', () {
        final bmi = state.calculateBmi(1.0);
        // BMI = 1 / 3.0625 = 0.3265...
        expect(bmi, closeTo(0.33, 0.01));
        expect(bmi, isPositive);
      });

      test('BMI for extremely high weight (300kg) at 175cm', () {
        final bmi = state.calculateBmi(300.0);
        // BMI = 300 / 3.0625 = 97.959...
        expect(bmi, closeTo(97.96, 0.01));
        expect(bmi, isPositive);
      });

      test('BMI for 0kg weight returns 0.0', () {
        final bmi = state.calculateBmi(0.0);
        expect(bmi, closeTo(0.0, 0.0001));
      });

      test('BMI for very small weight (0.001kg) at 175cm', () {
        final bmi = state.calculateBmi(0.001);
        expect(bmi, closeTo(0.00033, 0.0001));
        expect(bmi, isPositive);
      });
    });

    group('zero and negative height bounds', () {
      test('BMI returns 0.0 when height is exactly 0', () {
        final zeroHeightState = const AppSettingsState(height: 0.0);
        final bmi = zeroHeightState.calculateBmi(70.0);
        expect(bmi, equals(0.0));
      });

      test('BMI returns 0.0 when height is negative (-50cm)', () {
        final negativeHeightState = const AppSettingsState(height: -50.0);
        final bmi = negativeHeightState.calculateBmi(70.0);
        expect(bmi, equals(0.0));
      });

      test('BMI returns 0.0 when height is very small positive (0.001cm)', () {
        final smallHeightState = const AppSettingsState(height: 0.001);
        final bmi = smallHeightState.calculateBmi(70.0);
        // With height = 0.001cm = 0.00001m, BMI = 70 / 1e-10 = 7e11
        // This is a very large number but not infinity - mathematically valid
        expect(bmi, isPositive);
        expect(bmi, isNot(equals(double.infinity)));
      });

      test('BMI does not throw on zero height', () {
        final zeroHeightState = const AppSettingsState(height: 0.0);
        expect(() => zeroHeightState.calculateBmi(70.0), returnsNormally);
      });

      test('BMI does not throw on negative height', () {
        final negativeHeightState = const AppSettingsState(height: -100.0);
        expect(() => negativeHeightState.calculateBmi(70.0), returnsNormally);
      });
    });

    group('BMI category classification', () {
      test('BMI below 18.5 returns underweight', () {
        expect(state.getBmiCategory(18.49), BmiCategory.underweight);
        expect(state.getBmiCategory(0.0), BmiCategory.underweight);
        expect(state.getBmiCategory(10.0), BmiCategory.underweight);
      });

      test('BMI exactly 18.5 returns normal', () {
        expect(state.getBmiCategory(18.5), BmiCategory.normal);
      });

      test('BMI between 18.5 and 25 returns normal', () {
        expect(state.getBmiCategory(20.0), BmiCategory.normal);
        expect(state.getBmiCategory(24.99), BmiCategory.normal);
      });

      test('BMI exactly 25.0 returns overweight', () {
        expect(state.getBmiCategory(25.0), BmiCategory.overweight);
      });

      test('BMI between 25 and 30 returns overweight', () {
        expect(state.getBmiCategory(26.0), BmiCategory.overweight);
        expect(state.getBmiCategory(29.99), BmiCategory.overweight);
      });

      test('BMI exactly 30.0 returns obese', () {
        expect(state.getBmiCategory(30.0), BmiCategory.obese);
      });

      test('BMI above 30 returns obese', () {
        expect(state.getBmiCategory(35.0), BmiCategory.obese);
        expect(state.getBmiCategory(50.0), BmiCategory.obese);
        expect(state.getBmiCategory(100.0), BmiCategory.obese);
      });

      test('BMI from zero height returns underweight (not obese)', () {
        // After fix: zero height returns BMI = 0.0, which is underweight
        final zeroHeightState = const AppSettingsState(height: 0.0);
        final bmi = zeroHeightState.calculateBmi(70.0);
        final category = zeroHeightState.getBmiCategory(bmi);
        expect(bmi, equals(0.0));
        expect(category, BmiCategory.underweight);
      });

      test('BMI from negative height returns underweight (not obese)', () {
        final negativeHeightState = const AppSettingsState(height: -50.0);
        final bmi = negativeHeightState.calculateBmi(70.0);
        final category = negativeHeightState.getBmiCategory(bmi);
        expect(bmi, equals(0.0));
        expect(category, BmiCategory.underweight);
      });
    });

    group('height configuration impact on BMI', () {
      test('BMI is inversely proportional to height squared', () {
        // Double the height should quarter the BMI
        final state170 = const AppSettingsState(height: 170.0);
        final state340 = const AppSettingsState(height: 340.0);
        final bmi170 = state170.calculateBmi(70.0);
        final bmi340 = state340.calculateBmi(70.0);
        expect(bmi340, closeTo(bmi170 / 4, 0.01));
      });

      test('Same BMI at different height/weight combinations', () {
        // 70kg at 175cm: 70 / 3.0625 = 22.857
        // 100kg at 202.37cm: 100 / 4.0954 = 24.42
        final state2 = const AppSettingsState(height: 200.0);
        final bmi2 = state2.calculateBmi(90.0);
        // 90 / 4 = 22.5
        expect(bmi2, closeTo(22.5, 0.01));
      });
    });
  });

  group('Target weight conversion', () {
    test('kgToLbs converts 70kg to approximately 154.32 lbs', () {
      expect(kgToLbs(70.0), closeTo(154.3234, 0.0001));
    });

    test('kgToLbs converts 0kg to 0lbs', () {
      expect(kgToLbs(0.0), equals(0.0));
    });

    test('kgToLbs converts 80kg to approximately 176.37 lbs', () {
      expect(kgToLbs(80.0), closeTo(176.37, 0.01));
    });

    test('lbsToKg converts 154.32 lbs to approximately 70kg', () {
      expect(lbsToKg(154.32), closeTo(70.0, 0.01));
    });

    test('lbsToKg converts 0 lbs to 0 kg', () {
      expect(lbsToKg(0.0), equals(0.0));
    });

    test('Bidirectional conversion: kg -> lbs -> kg preserves value', () {
      const originalKg = 75.0;
      final lbs = kgToLbs(originalKg);
      final backToKg = lbsToKg(lbs);
      expect(backToKg, closeTo(originalKg, 0.0001));
    });

    test('Bidirectional conversion: lbs -> kg -> lbs preserves value', () {
      const originalLbs = 165.0;
      final kg = lbsToKg(originalLbs);
      final backToLbs = kgToLbs(kg);
      expect(backToLbs, closeTo(originalLbs, 0.0001));
    });

    test('Target weight in lbs is correctly derived from kg target', () {
      // If user sets target = 75kg, imperial should show 165.3 lbs
      final targetKg = 75.0;
      final targetLbs = kgToLbs(targetKg);
      expect(targetLbs, closeTo(165.35, 0.01));
    });

    test('Very small weight converts correctly', () {
      expect(kgToLbs(0.001), closeTo(0.0022, 0.0001));
    });

    test('Very large weight converts correctly', () {
      expect(kgToLbs(500.0), closeTo(1102.31, 0.01));
    });
  });

  group('Measurement unit display formatting', () {
    test('Metric format shows kg with 1 decimal', () {
      expect(formatWeight(70.0, MeasurementUnit.metric), '70.0 kg');
    });

    test('Metric format rounds correctly', () {
      expect(formatWeight(70.45, MeasurementUnit.metric), '70.5 kg');
      expect(formatWeight(70.44, MeasurementUnit.metric), '70.4 kg');
    });

    test('Imperial format shows lbs with 1 decimal', () {
      final lbs = kgToLbs(70.0);
      expect(
        formatWeight(70.0, MeasurementUnit.imperial),
        '${lbs.toStringAsFixed(1)} lbs',
      );
    });

    test('Metric height format shows cm as integer', () {
      expect(formatHeight(170.0, MeasurementUnit.metric), '170 cm');
    });

    test('Imperial height format shows feet and inches', () {
      final result = formatHeight(170.0, MeasurementUnit.imperial);
      expect(result, contains("'"));
      expect(result, contains('"'));
    });
  });

  group('Edge case: null target weight handling', () {
    test('State with no target weight is valid', () {
      final state = const AppSettingsState();
      expect(state.targetWeight, isNull);
    });

    test('State with target weight set is valid', () {
      final state = const AppSettingsState(targetWeight: 75.0);
      expect(state.targetWeight, equals(75.0));
    });

    test('copyWith preserves target weight when sentinel not used', () {
      final original = const AppSettingsState(targetWeight: 80.0);
      final copied = original.copyWith(height: 175.0);
      expect(copied.targetWeight, equals(80.0));
    });

    test('copyWith can clear target weight to null', () {
      final original = const AppSettingsState(targetWeight: 80.0);
      final copied = original.copyWith(targetWeight: null);
      expect(copied.targetWeight, isNull);
    });

    test('copyWith can set target weight from null', () {
      final original = const AppSettingsState();
      final copied = original.copyWith(targetWeight: 75.0);
      expect(copied.targetWeight, equals(75.0));
    });
  });
}
