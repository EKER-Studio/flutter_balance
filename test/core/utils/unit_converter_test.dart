import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

void main() {
  group('kgToLbs', () {
    test('converts 0 kg to 0 lbs', () {
      expect(kgToLbs(0), 0.0);
    });

    test('converts 1 kg to approximately 2.20462 lbs', () {
      expect(kgToLbs(1), closeTo(2.20462, 0.00001));
    });

    test('converts 70 kg to approximately 154.32 lbs', () {
      expect(kgToLbs(70), closeTo(154.3234, 0.0001));
    });

    test('converts 80 kg to approximately 176.37 lbs', () {
      expect(kgToLbs(80), closeTo(176.3696, 0.0001));
    });
  });

  group('lbsToKg', () {
    test('converts 0 lbs to 0 kg', () {
      expect(lbsToKg(0), 0.0);
    });

    test('converts 2.20462 lbs to approximately 1 kg', () {
      expect(lbsToKg(2.20462), closeTo(1.0, 0.00001));
    });

    test('converts 154.3234 lbs to approximately 70 kg', () {
      expect(lbsToKg(154.3234), closeTo(70.0, 0.0001));
    });
  });

  group('cmToFeetInches', () {
    test('converts 0 cm to 0 feet and 0 inches', () {
      final result = cmToFeetInches(0);
      expect(result[0], 0.0);
      expect(result[1], 0.0);
    });

    test('converts 170 cm to approximately 5 feet 7 inches', () {
      final result = cmToFeetInches(170);
      expect(result[0], 5.0);
      expect(result[1], closeTo(6.93, 0.01));
    });

    test('converts 183 cm to 6 feet 0 inches', () {
      final result = cmToFeetInches(183);
      expect(result[0], 6.0);
      expect(result[1], closeTo(0.05, 0.01));
    });
  });

  group('formatWeight', () {
    test('formats weight in metric as kg', () {
      expect(formatWeight(70.0, MeasurementUnit.metric), '70.0 kg');
    });

    test('formats weight in imperial as lbs', () {
      expect(formatWeight(70.0, MeasurementUnit.imperial), '154.3 lbs');
    });

    test('rounds weight correctly in metric', () {
      expect(formatWeight(70.45, MeasurementUnit.metric), '70.5 kg');
    });

    test('rounds weight correctly in imperial', () {
      expect(formatWeight(70.45, MeasurementUnit.imperial), '155.3 lbs');
    });
  });

  group('formatHeight', () {
    test('formats height in metric as cm', () {
      expect(formatHeight(170, MeasurementUnit.metric), '170 cm');
    });

    test('formats height in imperial as feet and inches', () {
      final result = formatHeight(170, MeasurementUnit.imperial);
      expect(result, contains("'"));
      expect(result, contains('"'));
    });

    test('formats 183 cm as 6\'0"', () {
      expect(formatHeight(183, MeasurementUnit.imperial), "6'0\"");
    });
  });
}
