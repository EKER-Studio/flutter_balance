import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:balance/core/integrations/analytics/analytics_service.dart';

/// Centralized telemetry dispatcher wrapping [AnalyticsService].
///
/// Ensures all application analytics events, screen views, and user properties
/// are safely logged without throwing exceptions or blocking execution.
class AppAnalytics {
  AppAnalytics._();

  static AnalyticsService _service = FirebaseAnalyticsService.instance;

  /// Injects or overrides the [AnalyticsService] delegate (e.g. for testing).
  ///
  /// @param service The analytics service instance.
  static void setService(AnalyticsService service) {
    _service = service;
  }

  /// Returns the underlying [FirebaseAnalytics] instance when available.
  static FirebaseAnalytics? get instance =>
      FirebaseAnalyticsService.instance.rawInstance;

  /// Sets whether Firebase Analytics is available and operational.
  ///
  /// @param available Flag declaring if Firebase has been initialized.
  static void setFirebaseAvailable(bool available) {
    _service.setAvailable(available);
  }

  /// Enables or disables analytics collection (e.g. for debug or privacy preference).
  ///
  /// @param enabled Flag indicating whether data collection should be active.
  static Future<void> setAnalyticsCollectionEnabled(bool enabled) {
    return _service.setAnalyticsCollectionEnabled(enabled);
  }

  /// Sets the unique identifier for the current user.
  ///
  /// @param id The user identifier string, or `null` to clear.
  static Future<void> setUserId(String? id) {
    return _service.setUserId(id);
  }

  /// Sets a custom user property.
  ///
  /// @param name The name of the property.
  /// @param value The value of the property, or `null` to clear.
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) {
    return _service.setUserProperty(name: name, value: value);
  }

  /// Logs a custom screen view event.
  ///
  /// @param screenName The human-readable name of the screen.
  /// @param screenClass Optional class name representing the screen widget.
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) {
    return _service.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Logs a generic custom telemetry event with optional parameters.
  ///
  /// @param name The event identifier string.
  /// @param parameters Optional map of parameter key-value pairs.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _service.logEvent(name: name, parameters: parameters);
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING EVENTS
  // ---------------------------------------------------------------------------

  /// Logs the start of the onboarding wizard flow.
  ///
  /// @param totalSteps Total number of steps in this session's flow.
  static Future<void> logOnboardingStarted(int totalSteps) {
    return logEvent(
      name: 'onboarding_started',
      parameters: {'total_steps': totalSteps},
    );
  }

  /// Logs when an individual onboarding step is displayed to the user.
  ///
  /// @param stepIndex The zero-based step index.
  /// @param stepName The identifier of the step.
  static Future<void> logOnboardingStepViewed({
    required int stepIndex,
    required String stepName,
  }) {
    return logEvent(
      name: 'onboarding_step_viewed',
      parameters: {'step_index': stepIndex, 'step_name': stepName},
    );
  }

  /// Logs the user completing an onboarding step and moving to the next one.
  ///
  /// @param stepIndex The zero-based index of the completed step.
  /// @param stepName The identifier of the completed step.
  /// @param isSkipped Whether the step was skipped without providing data.
  static Future<void> logOnboardingStepCompleted({
    required int stepIndex,
    required String stepName,
    required bool isSkipped,
  }) {
    return logEvent(
      name: 'onboarding_step_completed',
      parameters: {
        'step_index': stepIndex,
        'step_name': stepName,
        'is_skipped': isSkipped,
      },
    );
  }

  /// Logs the user tapping continue on the onboarding welcome step.
  static Future<void> logOnboardingWelcomeContinueClicked() {
    return logEvent(name: 'onboarding_welcome_continue_clicked');
  }

  /// Logs tapping on one of the feature preview cards on the welcome step.
  ///
  /// @param featureTitle The title of the inspected feature.
  static Future<void> logOnboardingWelcomeFeatureCardTapped(
    String featureTitle,
  ) {
    return logEvent(
      name: 'onboarding_welcome_feature_card_tapped',
      parameters: {'feature_title': featureTitle},
    );
  }

  /// Logs the unit system chosen during the units step of onboarding.
  ///
  /// @param unit The chosen measurement unit system ('metric' or 'imperial').
  static Future<void> logOnboardingUnitSelected(String unit) {
    return logEvent(
      name: 'onboarding_unit_selected',
      parameters: {'unit': unit},
    );
  }

  /// Logs tapping the metric/imperial unit segment tab during onboarding.
  ///
  /// @param unit The selected unit mode ('metric' or 'imperial').
  static Future<void> logOnboardingUnitsTabTapped(String unit) {
    return logEvent(
      name: 'onboarding_units_tab_tapped',
      parameters: {'unit': unit},
    );
  }

  /// Logs the height specified during the units & height step of onboarding.
  static Future<void> logOnboardingHeightChanged() {
    return logEvent(name: 'onboarding_height_changed');
  }

  /// Logs a validation error when entering height in onboarding.
  ///
  /// @param errorType Description of the validation error.
  static Future<void> logOnboardingHeightValidationError(String errorType) {
    return logEvent(
      name: 'onboarding_height_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs the initial body weight entered during the onboarding wizard.
  static Future<void> logOnboardingInitialWeightSet() {
    return logEvent(
      name: 'onboarding_initial_weight_set',
      parameters: {'has_value': true},
    );
  }

  /// Logs focusing the initial weight input field in onboarding.
  static Future<void> logOnboardingInitialWeightFieldFocused() {
    return logEvent(name: 'onboarding_initial_weight_field_focused');
  }

  /// Logs changing the text input for initial weight in onboarding.
  ///
  /// @param hasValue Whether the input field currently contains non-empty text.
  static Future<void> logOnboardingInitialWeightInputChanged(bool hasValue) {
    return logEvent(
      name: 'onboarding_initial_weight_input_changed',
      parameters: {'has_value': hasValue},
    );
  }

  /// Logs opening the date picker for the initial weight entry in onboarding.
  static Future<void> logOnboardingInitialWeightDatePickerOpened() {
    return logEvent(name: 'onboarding_initial_weight_date_picker_opened');
  }

  /// Logs selecting a custom date for the initial weight in onboarding.
  static Future<void> logOnboardingInitialWeightDateChanged() {
    return logEvent(name: 'onboarding_initial_weight_date_changed');
  }

  /// Logs opening the time picker for the initial weight entry in onboarding.
  static Future<void> logOnboardingInitialWeightTimePickerOpened() {
    return logEvent(name: 'onboarding_initial_weight_time_picker_opened');
  }

  /// Logs selecting a custom time for the initial weight in onboarding.
  ///
  /// @param hour Selected hour (0-23).
  /// @param minute Selected minute (0-59).
  static Future<void> logOnboardingInitialWeightTimeChanged({
    required int hour,
    required int minute,
  }) {
    return logEvent(
      name: 'onboarding_initial_weight_time_changed',
      parameters: {'hour': hour, 'minute': minute},
    );
  }

  /// Logs a validation error when entering initial weight in onboarding.
  ///
  /// @param errorType Description of the validation error.
  static Future<void> logOnboardingInitialWeightValidationError(
    String errorType,
  ) {
    return logEvent(
      name: 'onboarding_initial_weight_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs focusing or typing in the target weight input field during onboarding.
  ///
  /// @param hasValue Whether the input field contains text.
  static Future<void> logOnboardingTargetWeightInputChanged(bool hasValue) {
    return logEvent(
      name: 'onboarding_target_weight_input_changed',
      parameters: {'has_value': hasValue},
    );
  }

  /// Logs a validation error on the target weight step during onboarding.
  ///
  /// @param errorType Description of the validation error.
  static Future<void> logOnboardingTargetWeightValidationError(
    String errorType,
  ) {
    return logEvent(
      name: 'onboarding_target_weight_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs the target weight goal set during onboarding.
  static Future<void> logOnboardingTargetWeightSet() {
    return logEvent(
      name: 'onboarding_target_weight_set',
      parameters: {'has_target': true},
    );
  }

  /// Logs when the user opts to skip defining a target weight in onboarding.
  static Future<void> logOnboardingTargetWeightSkipped() {
    return logEvent(name: 'onboarding_target_weight_skipped');
  }

  /// Logs opening the file picker on the CSV import onboarding step.
  static Future<void> logOnboardingCsvPickerOpened() {
    return logEvent(name: 'onboarding_csv_picker_opened');
  }

  /// Logs cancelling the file picker without selecting a CSV file in onboarding.
  static Future<void> logOnboardingCsvPickerCancelled() {
    return logEvent(name: 'onboarding_csv_picker_cancelled');
  }

  /// Logs starting the background parsing of a selected CSV file in onboarding.
  static Future<void> logOnboardingCsvParsingStarted() {
    return logEvent(name: 'onboarding_csv_parsing_started');
  }

  /// Logs an error encountered while parsing a CSV file in onboarding.
  ///
  /// @param errorType Description of the failure ('empty_file', 'invalid_format', etc.).
  static Future<void> logOnboardingCsvImportError(String errorType) {
    return logEvent(
      name: 'onboarding_csv_import_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs clicking the retry action after a CSV import failure in onboarding.
  static Future<void> logOnboardingCsvRetryClicked() {
    return logEvent(name: 'onboarding_csv_retry_clicked');
  }

  /// Logs a successful CSV import during the onboarding wizard.
  ///
  /// @param entriesCount The number of imported entries.
  static Future<void> logOnboardingCsvImportSuccess(int entriesCount) {
    return logEvent(
      name: 'onboarding_csv_import_success',
      parameters: {'entries_count': entriesCount},
    );
  }

  /// Logs skipping the CSV import step during onboarding.
  static Future<void> logOnboardingCsvImportSkipped() {
    return logEvent(name: 'onboarding_csv_import_skipped');
  }

  /// Logs clicking the notification reminder toggle during onboarding.
  ///
  /// @param enabled Target state of the reminder toggle.
  static Future<void> logOnboardingReminderToggleClicked(bool enabled) {
    return logEvent(
      name: 'onboarding_reminder_toggle_clicked',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs opening the time picker on the reminder step of onboarding.
  static Future<void> logOnboardingReminderTimePickerOpened() {
    return logEvent(name: 'onboarding_reminder_time_picker_opened');
  }

  /// Logs selecting a reminder time in onboarding.
  ///
  /// @param hour Selected hour (0-23).
  /// @param minute Selected minute (0-59).
  static Future<void> logOnboardingReminderTimeSelected({
    required int hour,
    required int minute,
  }) {
    return logEvent(
      name: 'onboarding_reminder_time_selected',
      parameters: {'hour': hour, 'minute': minute},
    );
  }

  /// Logs clicking the health sync toggle in onboarding.
  ///
  /// @param enabled Target state of the sync toggle.
  static Future<void> logOnboardingHealthSyncToggleClicked(bool enabled) {
    return logEvent(
      name: 'onboarding_health_sync_toggle_clicked',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs toggling health integration during onboarding.
  ///
  /// @param enabled Whether health sync was toggled on or off.
  /// @param permissionGranted Whether OS health permissions were granted.
  static Future<void> logOnboardingHealthSyncToggled({
    required bool enabled,
    required bool permissionGranted,
  }) {
    return logEvent(
      name: 'onboarding_health_sync_toggled',
      parameters: {'enabled': enabled, 'permission_granted': permissionGranted},
    );
  }

  /// Logs clicking the biometric lock toggle in onboarding.
  ///
  /// @param enabled Target state of the biometrics toggle.
  static Future<void> logOnboardingBiometricsToggleClicked(bool enabled) {
    return logEvent(
      name: 'onboarding_biometrics_toggle_clicked',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs the result of the biometric test authentication in onboarding.
  ///
  /// @param success Whether biometric authentication succeeded.
  static Future<void> logOnboardingBiometricsAuthResult(bool success) {
    return logEvent(
      name: 'onboarding_biometrics_auth_result',
      parameters: {'success': success},
    );
  }

  /// Logs toggling biometric app lock during onboarding.
  ///
  /// @param enabled Whether biometric protection was enabled or disabled.
  static Future<void> logOnboardingBiometricsToggled(bool enabled) {
    return logEvent(
      name: 'onboarding_biometrics_toggled',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs navigating backward in the onboarding wizard.
  ///
  /// @param fromStepIndex The step index being left.
  /// @param toStepIndex The destination step index.
  static Future<void> logOnboardingStepBackClicked({
    required int fromStepIndex,
    required int toStepIndex,
  }) {
    return logEvent(
      name: 'onboarding_step_back_clicked',
      parameters: {
        'from_step_index': fromStepIndex,
        'to_step_index': toStepIndex,
      },
    );
  }

  /// Logs completing the entire onboarding wizard and entering the main app.
  ///
  /// @param hasInitialWeight Whether an initial measurement was entered.
  /// @param hasTargetWeight Whether a target goal was set.
  /// @param hasCsvData Whether CSV data was imported.
  /// @param healthSyncEnabled Whether health sync was activated.
  /// @param biometricsEnabled Whether biometric lock was activated.
  static Future<void> logOnboardingCompleted({
    required bool hasInitialWeight,
    required bool hasTargetWeight,
    required bool hasCsvData,
    required bool healthSyncEnabled,
    required bool biometricsEnabled,
  }) {
    return logEvent(
      name: 'onboarding_completed',
      parameters: {
        'has_initial_weight': hasInitialWeight,
        'has_target_weight': hasTargetWeight,
        'has_csv_data': hasCsvData,
        'health_sync_enabled': healthSyncEnabled,
        'biometrics_enabled': biometricsEnabled,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD (TODAY) EVENTS
  // ---------------------------------------------------------------------------

  /// Logs displaying the main Today dashboard tab.
  static Future<void> logTodayScreenViewed() {
    return logScreenView(screenName: 'today_screen');
  }

  /// Logs clicking the primary floating action button (+) to record weight.
  static Future<void> logTodayAddWeightFabClicked() {
    return logEvent(name: 'today_add_weight_fab_clicked');
  }

  /// Logs clicking the welcome card button to record the very first entry.
  static Future<void> logTodayFirstWeightButtonClicked() {
    return logEvent(name: 'today_first_weight_button_clicked');
  }

  /// Logs tapping on an existing weight entry in the daily history section.
  ///
  /// @param entryId Unique ID of the tapped entry.
  /// @param hasNote Whether the entry contains a text note.
  static Future<void> logTodayEntryTap({
    required int entryId,
    required bool hasNote,
  }) {
    return logEvent(
      name: 'today_entry_tap',
      parameters: {'entry_id': entryId, 'has_note': hasNote},
    );
  }

  /// Logs deleting an entry from the today list.
  ///
  /// @param entryId Unique ID of the deleted entry.
  static Future<void> logTodayEntryDelete(int entryId) {
    return logEvent(
      name: 'today_entry_delete_clicked',
      parameters: {'entry_id': entryId},
    );
  }

  /// Logs tapping on the BMI badge to open the BMI legend.
  ///
  /// @param category The classification category name.
  static Future<void> logTodayBmiBadgeTapped({required String category}) {
    return logEvent(
      name: 'today_bmi_badge_tapped',
      parameters: {'category': category},
    );
  }

  /// Logs tapping on the goal progress bar to edit the target weight.
  static Future<void> logTodayGoalProgressBarTapped() {
    return logEvent(name: 'today_goal_progress_bar_tapped');
  }

  /// Logs tapping on the goal bar when no target weight is set yet.
  static Future<void> logTodaySetGoalTapped() {
    return logEvent(name: 'today_set_goal_tapped');
  }

  /// Logs inspecting an individual data point on the today trend chart.
  static Future<void> logTodayChartPointTouched() {
    return logEvent(name: 'today_chart_point_touched');
  }

  /// Logs interacting with the daily tip card.
  static Future<void> logTodayDailyTipTapped() {
    return logEvent(name: 'today_daily_tip_tapped');
  }

  /// Logs changing the comparison period in the weight delta card.
  ///
  /// @param period Selected comparison period name.
  static Future<void> logTodayDeltaPeriodSelected(String period) {
    return logEvent(
      name: 'today_delta_period_selected',
      parameters: {'period': period},
    );
  }

  /// Logs pulling down the list to trigger a manual data refresh.
  static Future<void> logTodayPullToRefresh() {
    return logEvent(name: 'today_pull_to_refresh');
  }

  // ---------------------------------------------------------------------------
  // CALENDAR EVENTS
  // ---------------------------------------------------------------------------

  /// Logs displaying the Calendar tab.
  static Future<void> logCalendarScreenViewed() {
    return logScreenView(screenName: 'calendar_screen');
  }

  /// Logs switching the calendar month view.
  ///
  /// @param yearMonth Formatted string representing the new month (e.g. '2026-08').
  static Future<void> logCalendarMonthChanged(String yearMonth) {
    return logEvent(
      name: 'calendar_month_changed',
      parameters: {'year_month': yearMonth},
    );
  }

  /// Logs selecting a specific day on the calendar grid.
  ///
  /// @param hasEntry Whether one or more measurements exist for this date.
  static Future<void> logCalendarDaySelected({required bool hasEntry}) {
    return logEvent(
      name: 'calendar_day_selected',
      parameters: {'has_entry': hasEntry},
    );
  }

  /// Logs clicking the button to add a measurement for the selected calendar date.
  static Future<void> logCalendarAddMeasurementClicked() {
    return logEvent(name: 'calendar_add_measurement_clicked');
  }

  /// Logs swiping to change month view on the calendar grid.
  ///
  /// @param direction Swipe direction ('left' for next, 'right' for previous).
  static Future<void> logCalendarSwipeMonthChanged(String direction) {
    return logEvent(
      name: 'calendar_swipe_month_changed',
      parameters: {'direction': direction},
    );
  }

  /// Logs tapping on an existing weight entry in the calendar day list.
  ///
  /// @param entryId Unique ID of the tapped entry.
  /// @param hasNote Whether the entry contains a text note.
  static Future<void> logCalendarEntryClicked({
    required int entryId,
    required bool hasNote,
  }) {
    return logEvent(
      name: 'calendar_entry_clicked',
      parameters: {'entry_id': entryId, 'has_note': hasNote},
    );
  }

  /// Logs deleting an entry from the calendar day details sheet.
  ///
  /// @param entryId Unique ID of the deleted entry.
  static Future<void> logCalendarEntryDeleted(int entryId) {
    return logEvent(
      name: 'calendar_entry_deleted',
      parameters: {'entry_id': entryId},
    );
  }

  // ---------------------------------------------------------------------------
  // STATISTICS EVENTS
  // ---------------------------------------------------------------------------

  /// Logs displaying the Statistics tab.
  static Future<void> logStatisticsScreenViewed() {
    return logScreenView(screenName: 'statistics_screen');
  }

  /// Logs changing the time period filter for statistics charts and aggregates.
  ///
  /// @param period The name of the selected [TimePeriod].
  static Future<void> logStatisticsFilterChanged(String period) {
    return logEvent(
      name: 'statistics_filter_changed',
      parameters: {'period': period},
    );
  }

  /// Logs clicking the empty state CTA to add the first measurement from statistics.
  static Future<void> logStatisticsAddFirstMeasurementClicked() {
    return logEvent(name: 'statistics_add_first_measurement_clicked');
  }

  /// Logs inspecting an individual data point on the chart.
  static Future<void> logStatisticsChartPointTouched() {
    return logEvent(name: 'statistics_chart_point_touched');
  }

  /// Logs inspecting an individual BMI data point on the statistics BMI chart.
  static Future<void> logStatisticsBmiPointTouched() {
    return logEvent(name: 'statistics_bmi_point_touched');
  }

  /// Logs tapping the BMI legend button from the statistics BMI chart card.
  static Future<void> logStatisticsBmiLegendTapped() {
    return logEvent(name: 'statistics_bmi_legend_tapped');
  }

  /// Logs tapping the Hero Progress card in statistics.
  static Future<void> logStatisticsHeroProgressCardTapped() {
    return logEvent(name: 'statistics_hero_progress_card_tapped');
  }

  /// Logs tapping the Weight Range card in statistics.
  static Future<void> logStatisticsRangeCardTapped() {
    return logEvent(name: 'statistics_range_card_tapped');
  }

  /// Logs tapping the Habits Activity card in statistics.
  static Future<void> logStatisticsHabitsCardTapped() {
    return logEvent(name: 'statistics_habits_card_tapped');
  }

  /// Logs interacting with one of the Bento statistics cards.
  ///
  /// @param metricType The category of the metric (e.g. 'min', 'max', 'avg', 'velocity').
  static Future<void> logStatisticsMetricCardInspected(String metricType) {
    return logEvent(
      name: 'statistics_metric_card_inspected',
      parameters: {'metric_type': metricType},
    );
  }

  // ---------------------------------------------------------------------------
  // SETTINGS EVENTS
  // ---------------------------------------------------------------------------

  /// Logs displaying the Settings screen.
  static Future<void> logSettingsScreenViewed() {
    return logScreenView(screenName: 'settings_screen');
  }

  /// Logs tapping the height tile in settings.
  static Future<void> logSettingsHeightTileClicked() {
    return logEvent(name: 'settings_height_tile_clicked');
  }

  /// Logs opening the height editing dialog.
  ///
  /// @param currentHeightCm Pre-filled height value.
  /// @param unit The active measurement unit.
  static Future<void> logSettingsHeightDialogOpened({required String unit}) {
    return logEvent(
      name: 'settings_height_dialog_opened',
      parameters: {'unit': unit},
    );
  }

  /// Logs cancelling the height editing dialog.
  static Future<void> logSettingsHeightDialogCancelled() {
    return logEvent(name: 'settings_height_dialog_cancelled');
  }

  /// Logs a validation error in the height dialog.
  ///
  /// @param errorType Description of the validation failure.
  static Future<void> logSettingsHeightValidationError(String errorType) {
    return logEvent(
      name: 'settings_height_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs saving a new user height value in settings.
  static Future<void> logSettingsHeightSaved() {
    return logEvent(name: 'settings_height_saved');
  }

  /// Logs tapping the target weight tile in settings.
  static Future<void> logSettingsTargetWeightTileClicked() {
    return logEvent(name: 'settings_target_weight_tile_clicked');
  }

  /// Logs opening the target weight dialog in settings.
  ///
  /// @param unit The active measurement unit.
  static Future<void> logSettingsTargetWeightDialogOpened({
    required String unit,
  }) {
    return logEvent(
      name: 'settings_target_weight_dialog_opened',
      parameters: {'unit': unit},
    );
  }

  /// Logs a validation error in the target weight dialog.
  ///
  /// @param errorType Description of the validation failure.
  static Future<void> logSettingsTargetWeightValidationError(String errorType) {
    return logEvent(
      name: 'settings_target_weight_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs cancelling the target weight dialog.
  static Future<void> logSettingsTargetWeightDialogCancelled() {
    return logEvent(name: 'settings_target_weight_dialog_cancelled');
  }

  /// Logs saving a new target goal weight in settings.
  static Future<void> logSettingsTargetWeightSaved() {
    return logEvent(name: 'settings_target_weight_saved');
  }

  /// Logs removing/clearing the target weight in settings.
  static Future<void> logSettingsTargetWeightCleared() {
    return logEvent(name: 'settings_target_weight_cleared');
  }

  /// Logs tapping the unit selector tile in settings.
  ///
  /// @param currentUnit The current unit mode ('metric' or 'imperial').
  static Future<void> logSettingsUnitTileClicked(String currentUnit) {
    return logEvent(
      name: 'settings_unit_tile_clicked',
      parameters: {'current_unit': currentUnit},
    );
  }

  /// Logs opening the unit selection dialog.
  ///
  /// @param currentUnit The currently selected unit.
  static Future<void> logSettingsUnitDialogOpened(String currentUnit) {
    return logEvent(
      name: 'settings_unit_dialog_opened',
      parameters: {'current_unit': currentUnit},
    );
  }

  /// Logs cancelling the unit selection dialog.
  static Future<void> logSettingsUnitDialogCancelled() {
    return logEvent(name: 'settings_unit_dialog_cancelled');
  }

  /// Logs switching the preferred measurement unit system in settings.
  ///
  /// @param unit Selected unit system ('metric', 'imperial').
  static Future<void> logSettingsUnitChanged(String unit) {
    return logEvent(name: 'settings_unit_changed', parameters: {'unit': unit});
  }

  /// Logs tapping the theme selector tile in settings.
  ///
  /// @param currentTheme The current theme name.
  static Future<void> logSettingsThemeTileClicked(String currentTheme) {
    return logEvent(
      name: 'settings_theme_tile_clicked',
      parameters: {'current_theme': currentTheme},
    );
  }

  /// Logs opening the theme selection dialog.
  ///
  /// @param currentTheme The currently active theme mode.
  static Future<void> logSettingsThemeDialogOpened(String currentTheme) {
    return logEvent(
      name: 'settings_theme_dialog_opened',
      parameters: {'current_theme': currentTheme},
    );
  }

  /// Logs cancelling the theme selection dialog.
  static Future<void> logSettingsThemeDialogCancelled() {
    return logEvent(name: 'settings_theme_dialog_cancelled');
  }

  /// Logs changing the app theme mode.
  ///
  /// @param themeMode The new theme ('system', 'light', 'dark').
  static Future<void> logSettingsThemeChanged(String themeMode) {
    return logEvent(
      name: 'settings_theme_changed',
      parameters: {'theme_mode': themeMode},
    );
  }

  /// Logs clicking the reminder notification switch tile.
  ///
  /// @param enabled Target toggle value.
  static Future<void> logSettingsReminderTileClicked(bool enabled) {
    return logEvent(
      name: 'settings_reminder_tile_clicked',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs toggling daily reminder notifications in settings.
  ///
  /// @param enabled Whether notifications were toggled on or off.
  /// @param permissionGranted Optional flag indicating whether OS permissions were granted.
  static Future<void> logSettingsReminderToggled({
    required bool enabled,
    bool? permissionGranted,
  }) {
    return logEvent(
      name: 'settings_reminder_toggled',
      parameters: {
        'enabled': enabled,
        'permission_granted': ?permissionGranted,
      },
    );
  }

  /// Logs clicking the reminder time selection tile in settings.
  ///
  /// @param currentTime The currently scheduled time string.
  static Future<void> logSettingsReminderTimeTileClicked(String currentTime) {
    return logEvent(
      name: 'settings_reminder_time_tile_clicked',
      parameters: {'current_time': currentTime},
    );
  }

  /// Logs opening the reminder time picker in settings.
  ///
  /// @param hour Current hour.
  /// @param minute Current minute.
  static Future<void> logSettingsReminderTimePickerOpened({
    required int hour,
    required int minute,
  }) {
    return logEvent(
      name: 'settings_reminder_time_picker_opened',
      parameters: {'hour': hour, 'minute': minute},
    );
  }

  /// Logs cancelling the reminder time picker in settings.
  static Future<void> logSettingsReminderTimePickerCancelled() {
    return logEvent(name: 'settings_reminder_time_picker_cancelled');
  }

  /// Logs changing the daily notification reminder time.
  ///
  /// @param hour Target hour (0-23).
  /// @param minute Target minute (0-59).
  static Future<void> logSettingsReminderTimeChanged({
    required int hour,
    required int minute,
  }) {
    return logEvent(
      name: 'settings_reminder_time_changed',
      parameters: {'hour': hour, 'minute': minute},
    );
  }

  /// Logs toggling biometric app lock in settings.
  ///
  /// @param enabled Whether biometric locking was activated or deactivated.
  static Future<void> logSettingsBiometricsToggled(bool enabled) {
    return logEvent(
      name: 'settings_biometrics_toggled',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs starting a biometric verification test in settings.
  static Future<void> logSettingsBiometricsAuthStarted() {
    return logEvent(name: 'settings_biometrics_auth_started');
  }

  /// Logs biometric authentication success in settings.
  static Future<void> logSettingsBiometricsAuthSuccess() {
    return logEvent(name: 'settings_biometrics_auth_success');
  }

  /// Logs biometric authentication failure in settings.
  ///
  /// @param errorType Description of the authentication error.
  static Future<void> logSettingsBiometricsAuthFailed(String errorType) {
    return logEvent(
      name: 'settings_biometrics_auth_failed',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs the alert informing the user that biometrics is unavailable.
  static Future<void> logSettingsBiometricsUnavailableAlert() {
    return logEvent(name: 'settings_biometrics_unavailable_alert');
  }

  /// Logs toggling Health platform sync in settings.
  ///
  /// @param enabled Whether health sync was activated or deactivated.
  static Future<void> logSettingsHealthSyncToggled(bool enabled) {
    return logEvent(
      name: 'settings_health_sync_toggled',
      parameters: {'enabled': enabled},
    );
  }

  /// Logs opening the Health Connect install dialog.
  static Future<void> logSettingsHealthConnectInstallDialogOpened() {
    return logEvent(name: 'settings_health_connect_install_dialog_opened');
  }

  /// Logs clicking the button to open Google Play Store for Health Connect.
  static Future<void> logSettingsHealthConnectInstallDialogStoreClicked() {
    return logEvent(
      name: 'settings_health_connect_install_dialog_store_clicked',
    );
  }

  /// Logs cancelling the Health Connect install dialog.
  static Future<void> logSettingsHealthConnectInstallDialogCancelled() {
    return logEvent(name: 'settings_health_connect_install_dialog_cancelled');
  }

  /// Logs clicking the action to install Health Connect on Android.
  static Future<void> logSettingsHealthConnectInstallClicked() {
    return logEvent(name: 'settings_health_connect_install_clicked');
  }

  /// Logs clicking the button to export database entries to CSV.
  static Future<void> logSettingsCsvExportClicked() {
    return logEvent(name: 'settings_csv_export_clicked');
  }

  /// Logs the warning alert shown when attempting CSV export on an empty database.
  static Future<void> logSettingsCsvExportNoDataAlert() {
    return logEvent(name: 'settings_csv_export_no_data_alert');
  }

  /// Logs successfully generating and sharing a CSV export file.
  ///
  /// @param entriesCount Number of entries written to the CSV file.
  static Future<void> logSettingsCsvExportSuccess(int entriesCount) {
    return logEvent(
      name: 'settings_csv_export_success',
      parameters: {'entries_count': entriesCount},
    );
  }

  /// Logs failure during CSV export generation.
  ///
  /// @param errorMessage Error details.
  static Future<void> logSettingsCsvExportFailed(String errorMessage) {
    return logEvent(
      name: 'settings_csv_export_failed',
      parameters: {'error_message': errorMessage},
    );
  }

  /// Logs clicking the CSV import option in settings.
  static Future<void> logSettingsCsvImportClicked() {
    return logEvent(name: 'settings_csv_import_clicked');
  }

  /// Logs cancelling the file picker during CSV import in settings.
  static Future<void> logSettingsCsvImportPickerCancelled() {
    return logEvent(name: 'settings_csv_import_picker_cancelled');
  }

  /// Logs completing a CSV file import in settings.
  ///
  /// @param importedCount Number of entries added to the repository.
  static Future<void> logSettingsCsvImportCompleted(int importedCount) {
    return logEvent(
      name: 'settings_csv_import_completed',
      parameters: {'imported_count': importedCount},
    );
  }

  /// Logs clicking the wipe database tile in settings.
  static Future<void> logSettingsWipeTileClicked() {
    return logEvent(name: 'settings_wipe_tile_clicked');
  }

  /// Logs cancelling the wipe data dialog.
  static Future<void> logSettingsWipeDialogCancelled() {
    return logEvent(name: 'settings_wipe_dialog_cancelled');
  }

  /// Logs confirming full data erasure in settings.
  static Future<void> logSettingsWipeDataConfirmed() {
    return logEvent(name: 'settings_wipe_data_confirmed');
  }

  /// Logs successful database wipe execution.
  static Future<void> logSettingsWipeSuccess() {
    return logEvent(name: 'settings_wipe_success');
  }

  /// Logs a failure when executing database wipe.
  ///
  /// @param errorMessage Error description.
  static Future<void> logSettingsWipeFailed(String errorMessage) {
    return logEvent(
      name: 'settings_wipe_failed',
      parameters: {'error_message': errorMessage},
    );
  }

  /// Logs the warning alert shown when crash log file is empty.
  static Future<void> logSettingsShareCrashLogsEmptyAlert() {
    return logEvent(name: 'settings_share_crash_logs_empty_alert');
  }

  /// Logs successfully sharing the crash logs file.
  static Future<void> logSettingsShareCrashLogsSuccess() {
    return logEvent(name: 'settings_share_crash_logs_success');
  }

  /// Logs a failure when reading/sharing crash logs.
  ///
  /// @param errorMessage Error description.
  static Future<void> logSettingsShareCrashLogsFailed(String errorMessage) {
    return logEvent(
      name: 'settings_share_crash_logs_failed',
      parameters: {'error_message': errorMessage},
    );
  }

  /// Logs clicking the button to share application crash logs.
  static Future<void> logSettingsShareCrashLogsClicked() {
    return logEvent(name: 'settings_share_crash_logs_clicked');
  }

  /// Logs clicking the privacy policy tile in settings.
  static Future<void> logSettingsPrivacyPolicyClicked() {
    return logEvent(name: 'settings_privacy_policy_clicked');
  }

  /// Logs clicking the open source licenses tile in settings.
  static Future<void> logSettingsOpenSourceLicensesClicked() {
    return logEvent(name: 'settings_open_source_licenses_clicked');
  }

  /// Logs clicking the View on GitHub tile in settings.
  static Future<void> logSettingsViewOnGitHubClicked() {
    return logEvent(name: 'settings_view_on_github_clicked');
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION & DIALOG EVENTS
  // ---------------------------------------------------------------------------

  /// Logs switching main navigation tabs in the bottom bar.
  ///
  /// @param tabIndex The index of the selected tab (0-3).
  /// @param tabName The identifier of the tab.
  static Future<void> logNavigationTabSwitched({
    required int tabIndex,
    required String tabName,
  }) {
    return logEvent(
      name: 'navigation_tab_switched',
      parameters: {'tab_index': tabIndex, 'tab_name': tabName},
    );
  }

  /// Logs opening the add measurement modal dialog or bottom sheet.
  ///
  /// @param source Origin of the trigger (e.g. 'fab', 'empty_state', 'calendar').
  static Future<void> logDialogAddWeightOpened(String source) {
    return logEvent(
      name: 'dialog_add_weight_opened',
      parameters: {'source': source},
    );
  }

  /// Logs saving a measurement in the add weight dialog.
  ///
  /// @param hasNote Whether an accompanying note was included.
  /// @param isPastDate Whether the measurement date is set to a past timestamp.
  static Future<void> logDialogAddWeightSaved({
    required bool hasNote,
    required bool isPastDate,
  }) {
    return logEvent(
      name: 'dialog_add_weight_saved',
      parameters: {'has_note': hasNote, 'is_past_date': isPastDate},
    );
  }

  /// Logs opening the date picker in the add weight dialog.
  static Future<void> logDialogAddWeightDatePickerOpened() {
    return logEvent(name: 'dialog_add_weight_date_picker_opened');
  }

  /// Logs selecting a new measurement date in the add weight dialog.
  ///
  /// @param date Selected date string (YYYY-MM-DD).
  static Future<void> logDialogAddWeightDateChanged(String date) {
    return logEvent(
      name: 'dialog_add_weight_date_changed',
      parameters: {'date': date},
    );
  }

  /// Logs opening the time picker in the add weight dialog.
  static Future<void> logDialogAddWeightTimePickerOpened() {
    return logEvent(name: 'dialog_add_weight_time_picker_opened');
  }

  /// Logs selecting a new measurement time in the add weight dialog.
  ///
  /// @param hour Selected hour.
  /// @param minute Selected minute.
  static Future<void> logDialogAddWeightTimeChanged({
    required int hour,
    required int minute,
  }) {
    return logEvent(
      name: 'dialog_add_weight_time_changed',
      parameters: {'hour': hour, 'minute': minute},
    );
  }

  /// Logs a form validation failure in the add weight dialog.
  ///
  /// @param errorType Description of the validation error.
  static Future<void> logDialogAddWeightValidationError(String errorType) {
    return logEvent(
      name: 'dialog_add_weight_validation_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs closing the add weight dialog without saving.
  static Future<void> logDialogAddWeightCancelled() {
    return logEvent(name: 'dialog_add_weight_cancelled');
  }

  /// Logs closing the BMI legend modal dialog.
  static Future<void> logDialogBmiLegendClosed() {
    return logEvent(name: 'dialog_bmi_legend_closed');
  }

  /// Logs opening the edit weight dialog for an existing entry.
  ///
  /// @param entryId Unique ID of the entry being edited.
  static Future<void> logDialogEditWeightOpened(int entryId) {
    return logEvent(
      name: 'dialog_edit_weight_opened',
      parameters: {'entry_id': entryId},
    );
  }

  /// Logs saving changes to an entry in the edit weight dialog.
  ///
  /// @param hasNote Whether a note is present.
  /// @param dateModified Whether the entry's timestamp was changed.
  static Future<void> logDialogEditWeightSaved({
    required bool hasNote,
    required bool dateModified,
  }) {
    return logEvent(
      name: 'dialog_edit_weight_saved',
      parameters: {'has_note': hasNote, 'date_modified': dateModified},
    );
  }

  /// Logs displaying the CSV import analysis confirmation modal.
  ///
  /// @param validCount Number of parsed valid entries.
  /// @param invalidCount Number of rows skipped due to invalid format.
  /// @param duplicateCount Number of rows flagged as duplicates.
  static Future<void> logDialogCsvAnalysisOpened({
    required int validCount,
    required int invalidCount,
    required int duplicateCount,
  }) {
    return logEvent(
      name: 'dialog_csv_analysis_opened',
      parameters: {
        'valid_count': validCount,
        'invalid_count': invalidCount,
        'duplicate_count': duplicateCount,
      },
    );
  }

  /// Logs cancelling the CSV preview analysis dialog.
  static Future<void> logSettingsCsvPreviewDialogCancelled() {
    return logEvent(name: 'dialog_csv_preview_cancelled');
  }

  /// Logs an error during CSV import file analysis.
  ///
  /// @param errorType Description of the CSV analysis error.
  static Future<void> logDialogCsvAnalysisError(String errorType) {
    return logEvent(
      name: 'dialog_csv_analysis_error',
      parameters: {'error_type': errorType},
    );
  }

  /// Logs confirming and executing the bulk CSV import dialog.
  ///
  /// @param confirmedCount Number of entries committed to the database.
  static Future<void> logDialogCsvAnalysisConfirmed(int confirmedCount) {
    return logEvent(
      name: 'dialog_csv_analysis_confirmed',
      parameters: {'confirmed_count': confirmedCount},
    );
  }

  /// Logs opening the delete weight confirmation modal.
  ///
  /// @param entryId Identifier of the entry targeted for deletion.
  static Future<void> logDialogDeleteWeightOpened(int entryId) {
    return logEvent(
      name: 'dialog_delete_weight_opened',
      parameters: {'entry_id': entryId},
    );
  }

  /// Logs dismissing or cancelling the delete weight confirmation modal.
  static Future<void> logDialogDeleteWeightCancelled() {
    return logEvent(name: 'dialog_delete_weight_cancelled');
  }

  /// Logs opening the destructive wipe data confirmation dialog.
  static Future<void> logDialogWipeDataOpened() {
    return logEvent(name: 'dialog_wipe_data_opened');
  }

  /// Logs opening the biometric lock recovery dialog.
  ///
  /// @param reason Explanation for why recovery was initiated.
  static Future<void> logDialogLockRecoveryOpened(String reason) {
    return logEvent(
      name: 'dialog_lock_recovery_opened',
      parameters: {'reason': reason},
    );
  }

  /// Logs confirming lock recovery and resetting biometric preferences.
  static Future<void> logDialogLockRecoveryConfirmed() {
    return logEvent(name: 'dialog_lock_recovery_confirmed');
  }

  /// Logs displaying the Biometric Lock shield overlay screen.
  static Future<void> logBiometricShieldScreenViewed() {
    return logScreenView(screenName: 'biometric_shield_screen');
  }

  /// Logs tapping the unlock button on the biometric shield screen.
  static Future<void> logBiometricShieldUnlockTapped() {
    return logEvent(name: 'biometric_shield_unlock_tapped');
  }

  /// Logs successful biometric authentication on the shield screen.
  static Future<void> logBiometricShieldUnlockSuccess() {
    return logEvent(name: 'biometric_shield_unlock_success');
  }

  /// Logs a failed biometric unlock attempt on the shield screen.
  ///
  /// @param reason Failure outcome code or exception message.
  static Future<void> logBiometricShieldUnlockFailed(String reason) {
    return logEvent(
      name: 'biometric_shield_unlock_failed',
      parameters: {'reason': reason},
    );
  }

  /// Logs cancelling the biometric lock recovery dialog.
  static Future<void> logDialogLockRecoveryCancelled() {
    return logEvent(name: 'dialog_lock_recovery_cancelled');
  }

  /// Logs displaying the startup initialization error screen.
  static Future<void> logAppInitErrorScreenViewed() {
    return logScreenView(screenName: 'app_initialization_error_screen');
  }

  /// Logs tapping the retry button on the startup initialization error screen.
  static Future<void> logAppInitRetryClicked() {
    return logEvent(name: 'app_init_retry_clicked');
  }

  /// Logs tapping retry on the full-screen Today error state.
  static Future<void> logTodayErrorRetryClicked() {
    return logEvent(name: 'today_error_retry_clicked');
  }

  /// Logs tapping retry on the Today inline banner error.
  static Future<void> logTodayInlineBannerRetryClicked() {
    return logEvent(name: 'today_inline_banner_retry_clicked');
  }

  /// Logs tapping the main latest weight display on the Today hero summary card.
  ///
  /// @param unit The unit symbol ('kg' or 'lb').
  static Future<void> logTodayLatestWeightTapped({required String unit}) {
    return logEvent(
      name: 'today_latest_weight_tapped',
      parameters: {'unit': unit},
    );
  }

  /// Logs triggering pull-to-refresh on the Calendar screen.
  static Future<void> logCalendarPullToRefresh() {
    return logEvent(name: 'calendar_pull_to_refresh');
  }

  /// Logs tapping retry on the Calendar database error card.
  static Future<void> logCalendarErrorRetryClicked() {
    return logEvent(name: 'calendar_error_retry_clicked');
  }

  /// Logs triggering pull-to-refresh on the Statistics screen.
  static Future<void> logStatisticsPullToRefresh() {
    return logEvent(name: 'statistics_pull_to_refresh');
  }

  /// Logs tapping an individual habit/activity metric item on the Statistics screen.
  ///
  /// @param metricKey Key identifier for the habit metric (e.g. 'streak', 'frequency').
  static Future<void> logStatisticsHabitMetricTapped(String metricKey) {
    return logEvent(
      name: 'statistics_habit_metric_tapped',
      parameters: {'metric_key': metricKey},
    );
  }

  /// Logs tapping an individual weight detail row (highest/lowest/average) in statistics.
  ///
  /// @param label The label of the clicked statistic (e.g. 'highest', 'lowest', 'average').
  static Future<void> logStatisticsWeightDetailRowTapped(String label) {
    return logEvent(
      name: 'statistics_weight_detail_row_tapped',
      parameters: {'label': label},
    );
  }

  /// Logs tapping the app version tile in the settings help section.
  ///
  /// @param version The app version string.
  static Future<void> logSettingsAppVersionTapped(String version) {
    return logEvent(
      name: 'settings_app_version_tapped',
      parameters: {'version': version},
    );
  }

  /// Logs tapping a specific BMI category item in the BMI legend dialog.
  ///
  /// @param categoryName Name of the tapped BMI category.
  static Future<void> logDialogBmiLegendCategoryTapped(String categoryName) {
    return logEvent(
      name: 'dialog_bmi_legend_category_tapped',
      parameters: {'category_name': categoryName},
    );
  }

  /// Logs scheduling a daily reminder notification in the system service.
  ///
  /// @param hour Scheduled reminder hour.
  /// @param minute Scheduled reminder minute.
  /// @param isExact Flag indicating whether the alarm was scheduled with exact timing.
  static Future<void> logNotificationScheduled({
    required int hour,
    required int minute,
    required bool isExact,
  }) {
    return logEvent(
      name: 'notification_scheduled',
      parameters: {'hour': hour, 'minute': minute, 'is_exact': isExact},
    );
  }

  /// Logs cancelling the active daily reminder notification.
  static Future<void> logNotificationCancelled() {
    return logEvent(name: 'notification_cancelled');
  }

  /// Logs the start of an Apple Health or Google Health Connect sync cycle.
  static Future<void> logHealthSyncStarted() {
    return logEvent(name: 'health_sync_started');
  }

  /// Logs successful completion of a health data synchronization cycle.
  ///
  /// @param remoteCount Number of entries pulled from health platform.
  /// @param pushedLocalCount Number of local entries mirrored to health platform.
  static Future<void> logHealthSyncSuccess({
    required int remoteCount,
    required int pushedLocalCount,
  }) {
    return logEvent(
      name: 'health_sync_success',
      parameters: {
        'remote_count': remoteCount,
        'pushed_local_count': pushedLocalCount,
      },
    );
  }

  /// Logs an error during health data synchronization.
  ///
  /// @param error The failure description.
  static Future<void> logHealthSyncFailed(String error) {
    return logEvent(name: 'health_sync_failed', parameters: {'error': error});
  }

  /// Logs automatic biometric app locking when the application transitions to background.
  static Future<void> logBiometricBackgroundLocked() {
    return logEvent(name: 'biometric_background_locked');
  }

  /// Logs typing in the AddWeight dialog note field.
  ///
  /// @param hasNote Flag declaring if the note text field currently contains text.
  static Future<void> logDialogAddWeightNoteChanged(bool hasNote) {
    return logEvent(
      name: 'dialog_add_weight_note_changed',
      parameters: {'has_note': hasNote},
    );
  }

  /// Logs displaying the startup splash screen.
  static Future<void> logSplashScreenViewed() {
    return logScreenView(screenName: 'splash_screen');
  }

  /// Logs opening the BMI legend informational dialog.
  static Future<void> logDialogBmiLegendOpened() {
    return logEvent(name: 'dialog_bmi_legend_opened');
  }
}
