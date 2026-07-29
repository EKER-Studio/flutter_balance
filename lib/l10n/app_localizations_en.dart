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
  String get settingsTitle => 'Settings';

  @override
  String get metricUnit => 'Metric (kg, cm)';

  @override
  String get imperialUnit => 'Imperial (lb, ft/in)';

  @override
  String get height => 'Height';

  @override
  String get goal => 'Goal';

  @override
  String get targetWeight => 'Target Weight';

  @override
  String get notSet => 'Not set';

  @override
  String get security => 'Security';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get biometricDesc => 'Require Face ID or fingerprint on app launch';

  @override
  String get database => 'Database';

  @override
  String get importCsv => 'Import data from CSV';

  @override
  String get importCsvDesc =>
      'Import weight entries from a previously exported CSV file.';

  @override
  String get wipeData => 'Wipe All Data';

  @override
  String get wipeDataDesc =>
      'This will permanently delete all your weight entries and reset app settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Try again';

  @override
  String get invalidPositiveNumber => 'Please enter a valid positive number.';

  @override
  String get heightDialogTitle => 'Set Height';

  @override
  String get heightCmLabel => 'Height (cm)';

  @override
  String get heightHint => 'e.g. 177';

  @override
  String get targetWeightDialogTitle => 'Target Weight';

  @override
  String get weightInKgLabel => 'Weight (kg)';

  @override
  String get weightInLbLabel => 'Weight in lb';

  @override
  String get weightHint => 'e.g. 75.5';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get measurementUnit => 'Measurement Unit';

  @override
  String get biometricsNotAvailable =>
      'Biometrics not available on this device';

  @override
  String get wipeDataContent =>
      'This will permanently delete all your weight entries and reset app settings. This action cannot be undone.';

  @override
  String get wipeDataButton => 'Wipe Data';

  @override
  String get dataWipedSuccess => 'All data has been wiped. Restart the app.';

  @override
  String errorWipingData(Object error) {
    return 'Error wiping data: $error';
  }

  @override
  String get importNoDataFound =>
      'No valid weight entries found in the imported file.';

  @override
  String importSuccess(Object count) {
    return 'Imported $count entries.';
  }

  @override
  String get importFailed => 'Failed to import data.';

  @override
  String importError(Object error) {
    return 'Import error: $error';
  }

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get setYourHeightTitle => 'Set Your Height';

  @override
  String get emptyState => 'No entries yet. Add your first measurement below!';

  @override
  String get history => 'History';

  @override
  String get stats => 'Stats';

  @override
  String get lowest => 'Lowest';

  @override
  String get highest => 'Highest';

  @override
  String get toGoal => 'To Goal';

  @override
  String get reached => 'Reached!';

  @override
  String get latestMeasurement => 'Latest measurement';

  @override
  String get addWeight => 'Add Weight';

  @override
  String get weightCannotBeEmpty => 'Weight cannot be empty';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get weightRangeError => 'Weight must be between 20 and 300 kg';

  @override
  String get bmi => 'BMI';

  @override
  String bmiValue(Object value) {
    return 'BMI: $value';
  }

  @override
  String get bmiSubtitle => 'Based on your height and latest weight';

  @override
  String get weightGoal => 'Weight Goal';

  @override
  String get goalNotSet => 'Goal not set';

  @override
  String get goalAchieved => 'Goal achieved!';

  @override
  String get toTarget => 'to target';

  @override
  String get setGoalMotivation => 'Set a goal to stay motivated';

  @override
  String get rightOnTarget => 'You are right on target';

  @override
  String get targetLabel => 'Target:';

  @override
  String get chartEmpty => 'Not enough data to display chart.';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get all => 'All';

  @override
  String get chartTargetLabel => 'Target';

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

  @override
  String get biometricAuthReason => 'Authenticate to access PureWeight';

  @override
  String get appLocked => 'App Locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderDesc => 'Remind me to record weight daily';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get notificationsDisabledOs =>
      'Notifications are disabled at the system level.';

  @override
  String get openSettings => 'Settings';
}
