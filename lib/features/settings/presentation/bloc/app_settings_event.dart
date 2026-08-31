import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// A base class for all app settings events.
sealed class AppSettingsEvent {
  const AppSettingsEvent();
}

/// An event that updates the app's theme mode preference.
final class UpdateTheme extends AppSettingsEvent {
  final AppThemeMode themeMode;
  const UpdateTheme(this.themeMode);
}

/// An event that updates the preferred first day of the week.
final class UpdateFirstDayOfWeek extends AppSettingsEvent {
  final FirstDayOfWeek firstDayOfWeek;
  const UpdateFirstDayOfWeek(this.firstDayOfWeek);
}

/// An event that updates the weight measurement unit system.
final class UpdateMeasurementUnit extends AppSettingsEvent {
  final MeasurementUnit measurementUnit;
  const UpdateMeasurementUnit(this.measurementUnit);
}

/// An event that updates the user's height in centimeters.
final class UpdateHeight extends AppSettingsEvent {
  final double height;
  const UpdateHeight(this.height);
}

/// An event that toggles the daily notification reminder on or off.
///
/// Enabling requests OS notification permission and only schedules the
/// reminder when granted; disabling cancels the scheduled reminder.
final class ToggleNotifications extends AppSettingsEvent {
  final bool enabled;
  const ToggleNotifications(this.enabled);
}

/// An event that updates the time of day for the daily notification reminder.
///
/// The daily reminder is re-scheduled only while notifications are enabled.
final class UpdateNotificationTime extends AppSettingsEvent {
  final ({int hour, int minute}) notificationTime;
  const UpdateNotificationTime(this.notificationTime);
}

/// An event that updates the user's target weight in kg.
final class TargetWeightChanged extends AppSettingsEvent {
  /// The new target weight in kg (null to clear).
  final double? weight;

  const TargetWeightChanged(this.weight);
}

/// An event that updates the biometric lock enabled state.
final class UpdateBiometricLock extends AppSettingsEvent {
  final bool enabled;
  const UpdateBiometricLock(this.enabled);
}

/// An event that sets the app-wide locked state for the biometric shield.
final class SetLocked extends AppSettingsEvent {
  final bool locked;
  const SetLocked(this.locked);
}

/// An event that marks the initial onboarding wizard as completed.
final class CompleteOnboarding extends AppSettingsEvent {
  const CompleteOnboarding();
}

/// An event that sets whether biometric authentication is supported on this
/// device.
final class UpdateBiometricSupport extends AppSettingsEvent {
  final bool isSupported;
  const UpdateBiometricSupport(this.isSupported);
}

/// An event that toggles the health sync (HealthKit / Health Connect)
/// integration.
///
/// The resulting preference is persisted and restored on the next launch.
final class ToggleHealthSync extends AppSettingsEvent {
  final bool enabled;
  const ToggleHealthSync(this.enabled);
}

/// An event that re-evaluates health API availability and permission grants
/// on app start.
///
/// If health sync is enabled but the native permissions were revoked, the
/// sync flag is automatically disabled and persisted.
final class CheckHealthSyncStatus extends AppSettingsEvent {
  const CheckHealthSyncStatus();
}

/// An event that resets all application settings to factory default values.
final class ResetAppSettings extends AppSettingsEvent {
  const ResetAppSettings();
}

/// Records the timestamp of the last successful health sync.
final class UpdateLastHealthSyncTimestamp extends AppSettingsEvent {
  /// The UTC timestamp of the sync.
  final DateTime timestamp;

  const UpdateLastHealthSyncTimestamp(this.timestamp);
}

/// An event that updates the time window in days used for weekly pace calculations.
final class UpdateWeeklyPaceWindow extends AppSettingsEvent {
  /// The pace calculation window in days.
  final int windowDays;

  const UpdateWeeklyPaceWindow(this.windowDays);
}
