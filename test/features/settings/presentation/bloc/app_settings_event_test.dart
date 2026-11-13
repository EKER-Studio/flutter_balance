import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';

void main() {
  group('AppSettingsEvent construction', () {
    test('event instances carry their configured values', () {
      expect(const UpdateTheme(AppThemeMode.dark).themeMode, AppThemeMode.dark);
      expect(
        const UpdateMeasurementUnit(MeasurementUnit.imperial).measurementUnit,
        MeasurementUnit.imperial,
      );
      expect(const UpdateHeight(175.0).height, 175.0);
      expect(const ToggleNotifications(true).enabled, isTrue);
      expect(
        const UpdateNotificationTime((hour: 9, minute: 30)).notificationTime,
        (hour: 9, minute: 30),
      );
      expect(const TargetWeightChanged(80).weight, 80);
      expect(const TargetWeightChanged(null).weight, isNull);
      expect(const UpdateBiometricLock(true).enabled, isTrue);
      expect(const SetLocked(true).locked, isTrue);
      expect(const UpdateBiometricSupport(false).isSupported, isFalse);
      expect(const ToggleHealthSync(true).enabled, isTrue);
    });

    test('flag-less events are constructible', () {
      expect(const CompleteOnboarding(), isA<CompleteOnboarding>());
      expect(const DismissWidgetPromo(), isA<DismissWidgetPromo>());
      expect(const CheckHealthSyncStatus(), isA<CheckHealthSyncStatus>());
      expect(const ResetAppSettings(), isA<ResetAppSettings>());
    });

    test('UpdateFirstDayOfWeek carries the selected first day', () {
      expect(
        const UpdateFirstDayOfWeek(FirstDayOfWeek.monday).firstDayOfWeek,
        FirstDayOfWeek.monday,
      );
      expect(
        const UpdateFirstDayOfWeek(FirstDayOfWeek.sunday).firstDayOfWeek,
        FirstDayOfWeek.sunday,
      );
    });

    test('UpdateWeightGoalMode carries the selected goal mode', () {
      expect(
        const UpdateWeightGoalMode(WeightGoalMode.gain).goalMode,
        WeightGoalMode.gain,
      );
      expect(
        const UpdateWeightGoalMode(WeightGoalMode.maintain).goalMode,
        WeightGoalMode.maintain,
      );
    });

    test('TargetWeightChanged carries an optional goal mode', () {
      expect(
        const TargetWeightChanged(75.0, WeightGoalMode.lose).mode,
        WeightGoalMode.lose,
      );
      expect(const TargetWeightChanged(75.0).mode, isNull);
    });

    test('UpdateLastHealthSyncTimestamp carries a UTC timestamp', () {
      final timestamp = DateTime.utc(2024, 6, 15, 12, 30);
      expect(UpdateLastHealthSyncTimestamp(timestamp).timestamp, timestamp);
    });

    test('UpdateWeeklyPaceWindow carries the window in days', () {
      expect(const UpdateWeeklyPaceWindow(7).windowDays, 7);
      expect(const UpdateWeeklyPaceWindow(30).windowDays, 30);
    });

    test('telemetry opt-in/out events carry their flag', () {
      expect(const ToggleAnalytics(true).enabled, isTrue);
      expect(const ToggleAnalytics(false).enabled, isFalse);
      expect(const ToggleCrashReporting(true).enabled, isTrue);
      expect(const ToggleCrashReporting(false).enabled, isFalse);
    });

    test('parameterized events carry their values via a runtime instance', () {
      // A non-const argument (a list index) prevents each const constructor
      // from folding at compile time, so it runs at runtime and registers a
      // coverage hit without tripping prefer_const_constructors.
      final events = <AppSettingsEvent>[
        UpdateFirstDayOfWeek(FirstDayOfWeek.values.first),
        UpdateBiometricLock([false].first),
        UpdateBiometricSupport([true].first),
      ];

      expect(events, hasLength(3));
      expect(events, contains(isA<UpdateFirstDayOfWeek>()));
      expect(events, contains(isA<UpdateBiometricLock>()));
      expect(events, contains(isA<UpdateBiometricSupport>()));
    });
  });
}
