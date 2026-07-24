// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'PureWeight';

  @override
  String get bmiCategoryUnderweight => 'Niedowaga';

  @override
  String get bmiCategoryNormal => 'Norma';

  @override
  String get bmiCategoryOverweight => 'Nadwaga';

  @override
  String get bmiCategoryObese => 'Otyłość';

  @override
  String get bmiCategoryDescriptionUnderweight =>
      'BMI poniżej 18,5 — warto schudnąć';

  @override
  String get bmiCategoryDescriptionNormal =>
      'BMI między 18,5 a 24,9 — zakres zdrowy';

  @override
  String get bmiCategoryDescriptionOverweight =>
      'BMI między 25,0 a 29,9 — niewielki nadmiar wagi';

  @override
  String get bmiCategoryDescriptionObese =>
      'BMI 30,0 lub więcej — warto skonsultować się ze specjalistą';
}
