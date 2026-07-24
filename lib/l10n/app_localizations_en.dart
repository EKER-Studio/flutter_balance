// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PureWeight';

  @override
  String get bmiCategoryUnderweight => 'Underweight';

  @override
  String get bmiCategoryNormal => 'Normal';

  @override
  String get bmiCategoryOverweight => 'Overweight';

  @override
  String get bmiCategoryObese => 'Obese';

  @override
  String get bmiCategoryDescriptionUnderweight =>
      'BMI below 18.5 — you may need to gain weight';

  @override
  String get bmiCategoryDescriptionNormal =>
      'BMI between 18.5 and 24.9 — healthy range';

  @override
  String get bmiCategoryDescriptionOverweight =>
      'BMI between 25.0 and 29.9 — slight excess weight';

  @override
  String get bmiCategoryDescriptionObese =>
      'BMI 30.0 or higher — consider consulting a professional';
}
