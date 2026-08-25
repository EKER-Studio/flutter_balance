import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/analytics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAnalytics', () {
    setUp(() {
      AppAnalytics.setFirebaseAvailable(false);
    });

    test('setFirebaseAvailable and instance getter work safely', () {
      expect(AppAnalytics.instance, isNull);
      AppAnalytics.setFirebaseAvailable(true);
      // When Firebase.apps is empty in unit tests, getter returns null or initializes
      AppAnalytics.setFirebaseAvailable(false);
      expect(AppAnalytics.instance, isNull);
    });

    test(
      'all telemetry logging methods execute safely without throwing',
      () async {
        // Screen views
        await AppAnalytics.logScreenView(
          screenName: 'test_screen',
          screenClass: 'TestScreen',
        );
        await AppAnalytics.logTodayScreenViewed();
        await AppAnalytics.logCalendarScreenViewed();
        await AppAnalytics.logStatisticsScreenViewed();
        await AppAnalytics.logSettingsScreenViewed();

        // Onboarding
        await AppAnalytics.logOnboardingStarted(8);
        await AppAnalytics.logOnboardingStepViewed(
          stepIndex: 0,
          stepName: 'welcome',
        );
        await AppAnalytics.logOnboardingStepCompleted(
          stepIndex: 0,
          stepName: 'welcome',
          isSkipped: false,
        );
        await AppAnalytics.logOnboardingWelcomeContinueClicked();
        await AppAnalytics.logOnboardingWelcomeFeatureCardTapped(
          'Units & Height',
        );
        await AppAnalytics.logOnboardingUnitSelected('metric');
        await AppAnalytics.logOnboardingUnitsTabTapped('imperial');
        await AppAnalytics.logOnboardingHeightChanged();
        await AppAnalytics.logOnboardingHeightValidationError('range_error');
        await AppAnalytics.logOnboardingInitialWeightSet();
        await AppAnalytics.logOnboardingInitialWeightFieldFocused();
        await AppAnalytics.logOnboardingInitialWeightInputChanged(true);
        await AppAnalytics.logOnboardingInitialWeightDatePickerOpened();
        await AppAnalytics.logOnboardingInitialWeightDateChanged();
        await AppAnalytics.logOnboardingInitialWeightTimePickerOpened();
        await AppAnalytics.logOnboardingInitialWeightTimeChanged(
          hour: 8,
          minute: 30,
        );
        await AppAnalytics.logOnboardingInitialWeightValidationError(
          'required',
        );
        await AppAnalytics.logOnboardingTargetWeightInputChanged(true);
        await AppAnalytics.logOnboardingTargetWeightValidationError(
          'invalid_number',
        );
        await AppAnalytics.logOnboardingTargetWeightSet();
        await AppAnalytics.logOnboardingTargetWeightSkipped();
        await AppAnalytics.logOnboardingCsvPickerOpened();
        await AppAnalytics.logOnboardingCsvPickerCancelled();
        await AppAnalytics.logOnboardingCsvParsingStarted();
        await AppAnalytics.logOnboardingCsvImportError('empty_file');
        await AppAnalytics.logOnboardingCsvRetryClicked();
        await AppAnalytics.logOnboardingCsvImportSuccess(15);
        await AppAnalytics.logOnboardingCsvImportSkipped();
        await AppAnalytics.logOnboardingReminderToggleClicked(true);
        await AppAnalytics.logOnboardingReminderTimePickerOpened();
        await AppAnalytics.logOnboardingReminderTimeSelected(
          hour: 7,
          minute: 0,
        );
        await AppAnalytics.logOnboardingHealthSyncToggleClicked(true);
        await AppAnalytics.logOnboardingHealthSyncToggled(
          enabled: true,
          permissionGranted: true,
        );
        await AppAnalytics.logOnboardingBiometricsToggleClicked(true);
        await AppAnalytics.logOnboardingBiometricsAuthResult(true);
        await AppAnalytics.logOnboardingBiometricsToggled(true);
        await AppAnalytics.logOnboardingStepBackClicked(
          fromStepIndex: 2,
          toStepIndex: 1,
        );
        await AppAnalytics.logOnboardingCompleted(
          hasInitialWeight: true,
          hasTargetWeight: true,
          hasCsvData: false,
          healthSyncEnabled: true,
          biometricsEnabled: true,
        );

        // Dashboard
        await AppAnalytics.logTodayAddWeightFabClicked();
        await AppAnalytics.logTodayFirstWeightButtonClicked();
        await AppAnalytics.logTodayEntryTap(entryId: 1, hasNote: true);
        await AppAnalytics.logTodayEntryDelete(1);
        await AppAnalytics.logTodayBmiBadgeTapped(category: 'normal');
        await AppAnalytics.logTodayGoalProgressBarTapped();
        await AppAnalytics.logTodaySetGoalTapped();
        await AppAnalytics.logTodayChartPointTouched();
        await AppAnalytics.logTodayDailyTipTapped();
        await AppAnalytics.logTodayDeltaPeriodSelected('week');
        await AppAnalytics.logTodayPullToRefresh();

        // Calendar
        await AppAnalytics.logCalendarMonthChanged('2026-08');
        await AppAnalytics.logCalendarSwipeMonthChanged('left');
        await AppAnalytics.logCalendarDaySelected(hasEntry: true);
        await AppAnalytics.logCalendarAddMeasurementClicked();
        await AppAnalytics.logCalendarEntryClicked(entryId: 1, hasNote: true);
        await AppAnalytics.logCalendarEntryDeleted(1);

        // Statistics
        await AppAnalytics.logStatisticsAddFirstMeasurementClicked();
        await AppAnalytics.logStatisticsFilterChanged('month');
        await AppAnalytics.logStatisticsChartPointTouched();
        await AppAnalytics.logStatisticsBmiPointTouched();
        await AppAnalytics.logStatisticsBmiLegendTapped();
        await AppAnalytics.logStatisticsHeroProgressCardTapped();
        await AppAnalytics.logStatisticsRangeCardTapped();
        await AppAnalytics.logStatisticsHabitsCardTapped();
        await AppAnalytics.logStatisticsMetricCardInspected('min_weight');

        // Settings
        await AppAnalytics.logSettingsHeightTileClicked();
        await AppAnalytics.logSettingsHeightDialogOpened(unit: 'metric');
        await AppAnalytics.logSettingsHeightDialogCancelled();
        await AppAnalytics.logSettingsHeightValidationError('range_error');
        await AppAnalytics.logSettingsHeightSaved();
        await AppAnalytics.logSettingsTargetWeightTileClicked();
        await AppAnalytics.logSettingsTargetWeightDialogOpened(unit: 'metric');
        await AppAnalytics.logSettingsTargetWeightValidationError(
          'range_error',
        );
        await AppAnalytics.logSettingsTargetWeightDialogCancelled();
        await AppAnalytics.logSettingsTargetWeightSaved();
        await AppAnalytics.logSettingsTargetWeightCleared();
        await AppAnalytics.logSettingsUnitTileClicked('metric');
        await AppAnalytics.logSettingsUnitDialogOpened('metric');
        await AppAnalytics.logSettingsUnitDialogCancelled();
        await AppAnalytics.logSettingsUnitChanged('metric');
        await AppAnalytics.logSettingsThemeTileClicked('dark');
        await AppAnalytics.logSettingsThemeDialogOpened('dark');
        await AppAnalytics.logSettingsThemeDialogCancelled();
        await AppAnalytics.logSettingsThemeChanged('dark');
        await AppAnalytics.logSettingsReminderTileClicked(true);
        await AppAnalytics.logSettingsReminderToggled(
          enabled: true,
          permissionGranted: true,
        );
        await AppAnalytics.logSettingsReminderTimeTileClicked('08:30');
        await AppAnalytics.logSettingsReminderTimePickerOpened(
          hour: 8,
          minute: 30,
        );
        await AppAnalytics.logSettingsReminderTimePickerCancelled();
        await AppAnalytics.logSettingsReminderTimeChanged(hour: 8, minute: 30);
        await AppAnalytics.logSettingsBiometricsToggled(true);
        await AppAnalytics.logSettingsBiometricsAuthStarted();
        await AppAnalytics.logSettingsBiometricsAuthSuccess();
        await AppAnalytics.logSettingsBiometricsAuthFailed('notAvailable');
        await AppAnalytics.logSettingsBiometricsUnavailableAlert();
        await AppAnalytics.logSettingsHealthSyncToggled(true);
        await AppAnalytics.logSettingsHealthConnectInstallDialogOpened();
        await AppAnalytics.logSettingsHealthConnectInstallDialogStoreClicked();
        await AppAnalytics.logSettingsHealthConnectInstallDialogCancelled();
        await AppAnalytics.logSettingsHealthConnectInstallClicked();
        await AppAnalytics.logSettingsCsvExportClicked();
        await AppAnalytics.logSettingsCsvExportNoDataAlert();
        await AppAnalytics.logSettingsCsvExportSuccess(42);
        await AppAnalytics.logSettingsCsvExportFailed('disk full');
        await AppAnalytics.logSettingsCsvImportClicked();
        await AppAnalytics.logSettingsCsvImportPickerCancelled();
        await AppAnalytics.logSettingsCsvPreviewDialogCancelled();
        await AppAnalytics.logDialogCsvAnalysisError('invalidFormat');
        await AppAnalytics.logSettingsCsvImportCompleted(10);
        await AppAnalytics.logSettingsWipeTileClicked();
        await AppAnalytics.logSettingsWipeDialogCancelled();
        await AppAnalytics.logSettingsWipeDataConfirmed();
        await AppAnalytics.logSettingsWipeSuccess();
        await AppAnalytics.logSettingsWipeFailed('timeout');
        await AppAnalytics.logSettingsShareCrashLogsClicked();
        await AppAnalytics.logSettingsShareCrashLogsEmptyAlert();
        await AppAnalytics.logSettingsShareCrashLogsSuccess();
        await AppAnalytics.logSettingsShareCrashLogsFailed('share error');
        await AppAnalytics.logSettingsPrivacyPolicyClicked();

        // Navigation & Dialogs
        await AppAnalytics.logNavigationTabSwitched(
          tabIndex: 1,
          tabName: 'calendar',
        );
        await AppAnalytics.logDialogAddWeightOpened('fab');
        await AppAnalytics.logDialogAddWeightDatePickerOpened();
        await AppAnalytics.logDialogAddWeightDateChanged('2026-08-19');
        await AppAnalytics.logDialogAddWeightTimePickerOpened();
        await AppAnalytics.logDialogAddWeightTimeChanged(hour: 8, minute: 0);
        await AppAnalytics.logDialogAddWeightValidationError('range_error');
        await AppAnalytics.logDialogAddWeightSaved(
          hasNote: false,
          isPastDate: false,
        );
        await AppAnalytics.logDialogAddWeightCancelled();
        await AppAnalytics.logDialogEditWeightOpened(5);
        await AppAnalytics.logDialogEditWeightSaved(
          hasNote: true,
          dateModified: false,
        );
        await AppAnalytics.logDialogCsvAnalysisOpened(
          validCount: 10,
          invalidCount: 0,
          duplicateCount: 0,
        );
        await AppAnalytics.logDialogCsvAnalysisConfirmed(10);
        await AppAnalytics.logDialogDeleteWeightOpened(1);
        await AppAnalytics.logDialogDeleteWeightCancelled();
        await AppAnalytics.logDialogLockRecoveryOpened('biometric_lockout');
        await AppAnalytics.logDialogLockRecoveryCancelled();
        await AppAnalytics.logDialogLockRecoveryConfirmed();
        await AppAnalytics.logBiometricShieldScreenViewed();
        await AppAnalytics.logBiometricShieldUnlockTapped();
        await AppAnalytics.logBiometricShieldUnlockSuccess();
        await AppAnalytics.logBiometricShieldUnlockFailed('userCanceled');
        await AppAnalytics.logAppInitErrorScreenViewed();
        await AppAnalytics.logDialogBmiLegendOpened();
        await AppAnalytics.logDialogBmiLegendClosed();
        await AppAnalytics.logDialogBmiLegendCategoryTapped('normal');
        await AppAnalytics.logTodayErrorRetryClicked();
        await AppAnalytics.logTodayInlineBannerRetryClicked();
        await AppAnalytics.logTodayLatestWeightTapped(unit: 'kg');
        await AppAnalytics.logCalendarPullToRefresh();
        await AppAnalytics.logCalendarErrorRetryClicked();
        await AppAnalytics.logStatisticsPullToRefresh();
        await AppAnalytics.logStatisticsHabitMetricTapped('streak');
        await AppAnalytics.logStatisticsWeightDetailRowTapped('highest');
        await AppAnalytics.logSettingsAppVersionTapped('1.0.0');
        await AppAnalytics.logNotificationScheduled(
          hour: 8,
          minute: 30,
          isExact: true,
        );
        await AppAnalytics.logNotificationCancelled();
        await AppAnalytics.logHealthSyncStarted();
        await AppAnalytics.logHealthSyncSuccess(
          remoteCount: 5,
          pushedLocalCount: 2,
        );
        await AppAnalytics.logHealthSyncFailed('timeout');
        await AppAnalytics.logBiometricBackgroundLocked();
        await AppAnalytics.logDialogAddWeightNoteChanged(true);
        await AppAnalytics.logSplashScreenViewed();

        // User properties & generic
        await AppAnalytics.setUserId('user_123');
        await AppAnalytics.setUserProperty(
          name: 'test_prop',
          value: 'test_val',
        );
        await AppAnalytics.setAnalyticsCollectionEnabled(true);
      },
    );
  });
}
