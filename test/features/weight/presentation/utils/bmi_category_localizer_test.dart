import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';
import 'package:balance/presentation/bloc/settings/bmi_category.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('BmiCategoryX.localizedName', () {
    test('maps underweight to the localized string', () {
      expect(
        BmiCategory.underweight.localizedName(l10n),
        l10n.bmiCategoryUnderweight,
      );
    });

    test('maps normal to the localized string', () {
      expect(BmiCategory.normal.localizedName(l10n), l10n.bmiCategoryNormal);
    });

    test('maps overweight to the localized string', () {
      expect(
        BmiCategory.overweight.localizedName(l10n),
        l10n.bmiCategoryOverweight,
      );
    });

    test('maps obese to the localized string', () {
      expect(BmiCategory.obese.localizedName(l10n), l10n.bmiCategoryObese);
    });

    test('returns distinct labels for distinct categories', () {
      final labels = BmiCategory.values
          .map((c) => c.localizedName(l10n))
          .toSet();
      expect(labels.length, BmiCategory.values.length);
    });
  });

  group('BmiCategory.fromBmi', () {
    test('classifies below 18.5 as underweight', () {
      expect(BmiCategory.fromBmi(18.49), BmiCategory.underweight);
    });

    test('classifies 18.5 boundary as normal', () {
      expect(BmiCategory.fromBmi(18.5), BmiCategory.normal);
    });

    test('classifies 24.9 as normal', () {
      expect(BmiCategory.fromBmi(24.9), BmiCategory.normal);
    });

    test('classifies 25.0 boundary as overweight', () {
      expect(BmiCategory.fromBmi(25.0), BmiCategory.overweight);
    });

    test('classifies 29.9 as overweight', () {
      expect(BmiCategory.fromBmi(29.9), BmiCategory.overweight);
    });

    test('classifies 30.0 boundary as obese', () {
      expect(BmiCategory.fromBmi(30.0), BmiCategory.obese);
    });

    test('classifies high values as obese', () {
      expect(BmiCategory.fromBmi(41.7), BmiCategory.obese);
    });

    test('classifies zero as underweight', () {
      expect(BmiCategory.fromBmi(0), BmiCategory.underweight);
    });
  });
}
