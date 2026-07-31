import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PureWeight'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize the app to your needs'**
  String get settingsSubtitle;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileSection;

  /// No description provided for @applicationSection.
  ///
  /// In en, this message translates to:
  /// **'APPLICATION'**
  String get applicationSection;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get securitySection;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataSection;

  /// No description provided for @metricUnit.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, cm)'**
  String get metricUnit;

  /// No description provided for @imperialUnit.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lb, ft/in)'**
  String get imperialUnit;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get targetWeight;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// No description provided for @biometricDesc.
  ///
  /// In en, this message translates to:
  /// **'Require Face ID or fingerprint on app launch'**
  String get biometricDesc;

  /// No description provided for @biometricLockoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric lock unavailable'**
  String get biometricLockoutTitle;

  /// No description provided for @biometricLockoutBody.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are no longer available or enrolled on this device. Turn off the biometric lock to regain access to your data, or keep it locked.'**
  String get biometricLockoutBody;

  /// No description provided for @keepLocked.
  ///
  /// In en, this message translates to:
  /// **'Keep locked'**
  String get keepLocked;

  /// No description provided for @disableLock.
  ///
  /// In en, this message translates to:
  /// **'Turn off lock'**
  String get disableLock;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import data from CSV'**
  String get importCsv;

  /// No description provided for @wipeData.
  ///
  /// In en, this message translates to:
  /// **'Wipe All Data'**
  String get wipeData;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @invalidPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive number.'**
  String get invalidPositiveNumber;

  /// No description provided for @heightDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Height'**
  String get heightDialogTitle;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 177'**
  String get heightHint;

  /// No description provided for @targetWeightDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get targetWeightDialogTitle;

  /// No description provided for @weightInKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightInKgLabel;

  /// No description provided for @weightInLbLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight in lb'**
  String get weightInLbLabel;

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 75.5'**
  String get weightHint;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @measurementUnit.
  ///
  /// In en, this message translates to:
  /// **'Measurement Unit'**
  String get measurementUnit;

  /// No description provided for @biometricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device'**
  String get biometricsNotAvailable;

  /// No description provided for @wipeDataContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your weight entries and reset app settings. This action cannot be undone.'**
  String get wipeDataContent;

  /// No description provided for @wipeDataButton.
  ///
  /// In en, this message translates to:
  /// **'Wipe Data'**
  String get wipeDataButton;

  /// No description provided for @dataWipedSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been wiped. Restart the app.'**
  String get dataWipedSuccess;

  /// No description provided for @errorWipingData.
  ///
  /// In en, this message translates to:
  /// **'Error wiping data: {error}'**
  String errorWipingData(Object error);

  /// No description provided for @importNoDataFound.
  ///
  /// In en, this message translates to:
  /// **'No valid weight entries found in the imported file.'**
  String get importNoDataFound;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} entries.'**
  String importSuccess(Object count);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error: {error}'**
  String importError(Object error);

  /// No description provided for @notificationReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to weigh yourself!'**
  String get notificationReminderTitle;

  /// No description provided for @notificationReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Log your weight today and stay on track with PureWeight.'**
  String get notificationReminderBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily Weight Reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to record your daily weight measurement.'**
  String get notificationChannelDescription;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Add your first measurement below!'**
  String get emptyState;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PureWeight!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first measurement to start tracking your progress towards better health.'**
  String get welcomeSubtitle;

  /// No description provided for @addFirstMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add first measurement'**
  String get addFirstMeasurement;

  /// No description provided for @lowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get lowest;

  /// No description provided for @highest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get highest;

  /// No description provided for @latestMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Latest measurement'**
  String get latestMeasurement;

  /// No description provided for @addWeight.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get addWeight;

  /// No description provided for @measurementDate.
  ///
  /// In en, this message translates to:
  /// **'Measurement date'**
  String get measurementDate;

  /// No description provided for @measurementTime.
  ///
  /// In en, this message translates to:
  /// **'Measurement time'**
  String get measurementTime;

  /// No description provided for @futureDateError.
  ///
  /// In en, this message translates to:
  /// **'Date and time cannot be in the future'**
  String get futureDateError;

  /// No description provided for @weightCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Weight cannot be empty'**
  String get weightCannotBeEmpty;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @weightRangeError.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 20 and 300 kg'**
  String get weightRangeError;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @bmiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your height and latest weight'**
  String get bmiSubtitle;

  /// No description provided for @lastUpdatedToday.
  ///
  /// In en, this message translates to:
  /// **'Last updated: Today'**
  String get lastUpdatedToday;

  /// No description provided for @lastUpdatedDate.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdatedDate(Object date);

  /// No description provided for @setWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Set weight goal'**
  String get setWeightGoal;

  /// No description provided for @weightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight trend'**
  String get weightTrend;

  /// No description provided for @weightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight Goal'**
  String get weightGoal;

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved!'**
  String get goalAchieved;

  /// No description provided for @toTarget.
  ///
  /// In en, this message translates to:
  /// **'to target'**
  String get toTarget;

  /// No description provided for @chartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display chart.'**
  String get chartEmpty;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @chartTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get chartTargetLabel;

  /// No description provided for @bmiCategoryUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiCategoryUnderweight;

  /// No description provided for @bmiCategoryNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiCategoryNormal;

  /// No description provided for @bmiCategoryOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiCategoryOverweight;

  /// No description provided for @bmiCategoryObese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiCategoryObese;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access PureWeight'**
  String get biometricAuthReason;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLocked;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind me to record weight daily'**
  String get dailyReminderDesc;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @notificationsDisabledOs.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled at the system level.'**
  String get notificationsDisabledOs;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @errorStream.
  ///
  /// In en, this message translates to:
  /// **'Database stream error.'**
  String get errorStream;

  /// No description provided for @errorHeightNotSet.
  ///
  /// In en, this message translates to:
  /// **'Set your height first.'**
  String get errorHeightNotSet;

  /// No description provided for @errorAddEntryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add weight entry.'**
  String get errorAddEntryFailed;

  /// No description provided for @errorDeleteEntryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete weight entry.'**
  String get errorDeleteEntryFailed;

  /// No description provided for @errorReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read weight data.'**
  String get errorReadFailed;

  /// No description provided for @errorWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save weight data.'**
  String get errorWriteFailed;

  /// No description provided for @errorWipeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear weight data.'**
  String get errorWipeFailed;

  /// No description provided for @deleteEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTooltip;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this entry.'**
  String get deleteEntryMessage;

  /// No description provided for @skippedRows.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} rows'**
  String skippedRows(Object count);

  /// No description provided for @chartSemanticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight history line chart for {period} period. Latest recorded weight is {weight}.'**
  String chartSemanticsTitle(Object period, Object weight);

  /// No description provided for @chartSemanticsFilter.
  ///
  /// In en, this message translates to:
  /// **'filter'**
  String get chartSemanticsFilter;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @noEntriesToday.
  ///
  /// In en, this message translates to:
  /// **'No weight measurements recorded today.'**
  String get noEntriesToday;

  /// No description provided for @addMeasurementForDate.
  ///
  /// In en, this message translates to:
  /// **'Add measurement for {date}'**
  String addMeasurementForDate(Object date);

  /// No description provided for @missingData.
  ///
  /// In en, this message translates to:
  /// **'Missing data'**
  String get missingData;

  /// No description provided for @singleEntry.
  ///
  /// In en, this message translates to:
  /// **'1 measurement'**
  String get singleEntry;

  /// No description provided for @multipleEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} measurements'**
  String multipleEntries(int count);

  /// No description provided for @loggingStreak.
  ///
  /// In en, this message translates to:
  /// **'Logging Streak'**
  String get loggingStreak;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} one{{count} day} other{{count} days}}'**
  String streakDays(num count);

  /// No description provided for @trendPercentChange.
  ///
  /// In en, this message translates to:
  /// **'Trend: {value}'**
  String trendPercentChange(Object value);

  /// No description provided for @totalProgressUnitSuffix.
  ///
  /// In en, this message translates to:
  /// **'{unit} total'**
  String totalProgressUnitSuffix(Object unit);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @monthlyCompliance.
  ///
  /// In en, this message translates to:
  /// **'Monthly Consistency'**
  String get monthlyCompliance;

  /// No description provided for @averageWeight.
  ///
  /// In en, this message translates to:
  /// **'Average Weight'**
  String get averageWeight;

  /// No description provided for @totalProgress.
  ///
  /// In en, this message translates to:
  /// **'Total Progress'**
  String get totalProgress;

  /// No description provided for @noEntriesForDate.
  ///
  /// In en, this message translates to:
  /// **'No measurements recorded for this day'**
  String get noEntriesForDate;

  /// No description provided for @noEntriesForDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No data added for the selected date yet. Regular measurements help track progress better.'**
  String get noEntriesForDateSubtitle;

  /// No description provided for @futureDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Future date'**
  String get futureDateTitle;

  /// No description provided for @futureDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You cannot add weight measurements for future dates. Check previous days or return to today.'**
  String get futureDateSubtitle;

  /// No description provided for @goToToday.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get goToToday;

  /// No description provided for @goalAchievedOnDayBanner.
  ///
  /// In en, this message translates to:
  /// **'Weight goal was achieved on this day! 🏆'**
  String get goalAchievedOnDayBanner;

  /// No description provided for @dailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummaryTitle;

  /// No description provided for @rangeMinMax.
  ///
  /// In en, this message translates to:
  /// **'Range (Min / Max)'**
  String get rangeMinMax;

  /// No description provided for @goalChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalChipLabel;

  /// No description provided for @deleteMeasurementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete measurement'**
  String get deleteMeasurementTooltip;

  /// No description provided for @addAnotherMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add another measurement'**
  String get addAnotherMeasurement;

  /// No description provided for @entriesFromDate.
  ///
  /// In en, this message translates to:
  /// **'Entries from {date}'**
  String entriesFromDate(String date);

  /// No description provided for @databaseErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Database read error'**
  String get databaseErrorTitle;

  /// No description provided for @databaseErrorDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load weight history from the local database. Please try again.'**
  String get databaseErrorDefaultMessage;

  /// No description provided for @noEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'No measurements'**
  String get noEntriesLabel;

  /// No description provided for @futureDateSuffix.
  ///
  /// In en, this message translates to:
  /// **'Future date'**
  String get futureDateSuffix;

  /// No description provided for @selectedSuffix.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectedSuffix;

  /// No description provided for @todayTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight & BMI'**
  String get todayTabTitle;

  /// No description provided for @todayAtTime.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayAtTime(String time);

  /// No description provided for @tapToViewDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to view details'**
  String get tapToViewDetailsHint;

  /// No description provided for @bmiCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI Category: {category}'**
  String bmiCategoryLabel(String category);

  /// No description provided for @bmiValueLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI Value: {value} kg/m²'**
  String bmiValueLabel(String value);

  /// No description provided for @heightNotSetLabel.
  ///
  /// In en, this message translates to:
  /// **'height not set'**
  String get heightNotSetLabel;

  /// No description provided for @doubleTapToOpenCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to open calendar'**
  String get doubleTapToOpenCalendarHint;

  /// No description provided for @doubleTapToChangeTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to change time'**
  String get doubleTapToChangeTimeHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
