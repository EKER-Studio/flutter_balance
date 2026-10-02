import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kgToLbs', () {
    test('converts 0 kg to 0 lbs', () {
      expect(kgToLbs(0), 0.0);
    });

    test('converts 1 kg to 2.20462 lbs', () {
      expect(kgToLbs(1), closeTo(2.20462, 0.00001));
    });

    test('converts 70 kg to expected lbs', () {
      expect(kgToLbs(70), closeTo(154.3234, 0.0001));
    });

    test('converts 100 kg to expected lbs', () {
      expect(kgToLbs(100), closeTo(220.462, 0.0001));
    });

    test('handles negative values', () {
      expect(kgToLbs(-5), closeTo(-11.0231, 0.0001));
    });

    test('handles fractional values', () {
      expect(kgToLbs(0.5), closeTo(1.10231, 0.0001));
    });
  });

  group('lbsToKg', () {
    test('converts 0 lbs to 0 kg', () {
      expect(lbsToKg(0), 0.0);
    });

    test('converts 2.20462 lbs to 1 kg', () {
      expect(lbsToKg(2.20462), closeTo(1.0, 0.00001));
    });

    test('converts 220.462 lbs to 100 kg', () {
      expect(lbsToKg(220.462), closeTo(100.0, 0.0001));
    });

    test('handles negative values', () {
      expect(lbsToKg(-11.0231), closeTo(-5.0, 0.0001));
    });

    test('handles fractional values', () {
      expect(lbsToKg(1.10231), closeTo(0.5, 0.0001));
    });
  });

  group('kgToLbs / lbsToKg round-trip', () {
    test('kg -> lbs -> kg returns original value', () {
      const kg = 75.4;
      expect(lbsToKg(kgToLbs(kg)), closeTo(kg, 0.0001));
    });

    test('lbs -> kg -> lbs returns original value', () {
      const lbs = 165.7;
      expect(kgToLbs(lbsToKg(lbs)), closeTo(lbs, 0.0001));
    });
  });

  group('cmToFeetInches', () {
    test('converts 0 cm to 0 feet 0 inches', () {
      final result = cmToFeetInches(0);
      expect(result, [0.0, 0.0]);
    });

    test('converts 170 cm to 5 feet ~7 inches', () {
      final result = cmToFeetInches(170);
      expect(result[0], 5.0);
      expect(result[1], closeTo(6.9291, 0.01));
    });

    test('converts 182.88 cm to exactly 6 feet 0 inches', () {
      final result = cmToFeetInches(182.88);
      expect(result[0], 6.0);
      expect(result[1], closeTo(0, 0.001));
    });

    test('converts 121.92 cm to exactly 4 feet 0 inches', () {
      final result = cmToFeetInches(121.92);
      expect(result[0], 4.0);
      expect(result[1], closeTo(0, 0.001));
    });

    test('handles values below one foot', () {
      final result = cmToFeetInches(20);
      expect(result[0], 0.0);
      expect(result[1], closeTo(7.874, 0.01));
    });

    test('returns a list of exactly 2 doubles', () {
      final result = cmToFeetInches(170);
      expect(result.length, 2);
      expect(result[0], isA<double>());
      expect(result[1], isA<double>());
    });
  });

  group('formatWeight', () {
    test('formats metric weight in kg', () {
      expect(formatWeight(70.0, MeasurementUnit.metric), '70.0 kg');
    });

    test('formats imperial weight in lbs', () {
      expect(formatWeight(70.0, MeasurementUnit.imperial), '154.3 lbs');
    });

    test('rounds to one decimal in metric', () {
      expect(formatWeight(70.45, MeasurementUnit.metric), '70.5 kg');
    });

    test('rounds to one decimal in imperial', () {
      expect(formatWeight(70.45, MeasurementUnit.imperial), '155.3 lbs');
    });

    test('formats zero weight in metric', () {
      expect(formatWeight(0.0, MeasurementUnit.metric), '0.0 kg');
    });

    test('formats zero weight in imperial', () {
      expect(formatWeight(0.0, MeasurementUnit.imperial), '0.0 lbs');
    });
  });

  group('formatHeight', () {
    test('formats metric height in cm', () {
      expect(formatHeight(170, MeasurementUnit.metric), '170 cm');
    });

    test('rounds metric height to integer cm', () {
      expect(formatHeight(170.4, MeasurementUnit.metric), '170 cm');
    });

    test('formats imperial height with feet and inches', () {
      expect(formatHeight(182.88, MeasurementUnit.imperial), "6'0\"");
    });

    test('formats 170 cm as 5 feet 7 inches', () {
      expect(formatHeight(170, MeasurementUnit.imperial), "5'7\"");
    });

    test('formats 0 cm in metric', () {
      expect(formatHeight(0, MeasurementUnit.metric), '0 cm');
    });
  });

  group('formatHeightInput', () {
    test('formats whole numbers without decimals', () {
      expect(formatHeightInput(175.0), '175');
    });

    test('preserves one decimal place', () {
      expect(formatHeightInput(177.6), '177.6');
    });

    test('trims a second decimal place', () {
      expect(formatHeightInput(177.64), '177.6');
    });

    test('formats zero without decimals', () {
      expect(formatHeightInput(0.0), '0');
    });

    test('formats fractional inches without trailing zero', () {
      expect(formatHeightInput(9.921259), '9.9');
    });
  });

  group('tryParseLocalizedNumber', () {
    test('parses dot decimals', () {
      expect(tryParseLocalizedNumber('177.6'), closeTo(177.6, 0.001));
    });

    test('parses comma decimals (e.g. PL/DE keyboards)', () {
      expect(tryParseLocalizedNumber('177,6'), closeTo(177.6, 0.001));
    });

    test('trims surrounding whitespace', () {
      expect(tryParseLocalizedNumber('  180  '), 180.0);
    });

    test('returns null for blank input', () {
      expect(tryParseLocalizedNumber(''), isNull);
      expect(tryParseLocalizedNumber('   '), isNull);
    });

    test('returns null for unparseable input', () {
      expect(tryParseLocalizedNumber('abc'), isNull);
      expect(tryParseLocalizedNumber('180 cm'), isNull);
    });
  });

  group('tryParseImperialHeightCm', () {
    test('converts feet and inches to cm', () {
      expect(tryParseImperialHeightCm('5', '9'), closeTo(175.26, 0.01));
    });

    test('parses comma decimals in imperial fields', () {
      expect(tryParseImperialHeightCm('5,5', '0'), closeTo(167.64, 0.01));
    });

    test('treats empty feet as zero (inches-only input)', () {
      expect(tryParseImperialHeightCm('', '70'), closeTo(177.8, 0.01));
    });

    test('treats empty inches as zero', () {
      expect(tryParseImperialHeightCm('5', ''), closeTo(152.4, 0.01));
    });

    test('returns zero for a completely empty form', () {
      expect(tryParseImperialHeightCm('', ''), 0.0);
    });

    test('returns null for negative values', () {
      expect(tryParseImperialHeightCm('5', '-1'), isNull);
      expect(tryParseImperialHeightCm('-1', '0'), isNull);
    });

    test('returns null for unparseable values', () {
      expect(tryParseImperialHeightCm('five', '9'), isNull);
    });
  });

  group('heightValidationErrorType', () {
    test('reports empty for blank input', () {
      expect(
        heightValidationErrorType(isEmpty: true, parsedValue: null),
        'empty',
      );
    });

    test('reports parse_error for unparseable input', () {
      expect(
        heightValidationErrorType(isEmpty: false, parsedValue: null),
        'parse_error',
      );
    });

    test('reports out_of_range for parsed but invalid values', () {
      expect(
        heightValidationErrorType(isEmpty: false, parsedValue: 1.75),
        'out_of_range',
      );
    });
  });

  group('unitLabelFor', () {
    test('returns kg for metric', () {
      expect(unitLabelFor(MeasurementUnit.metric), 'kg');
    });

    test('returns lb for imperial', () {
      expect(unitLabelFor(MeasurementUnit.imperial), 'lb');
    });
  });

  group('bmiUnitLabel', () {
    test('is kg/m²', () {
      expect(bmiUnitLabel, 'kg/m²');
    });
  });
}
