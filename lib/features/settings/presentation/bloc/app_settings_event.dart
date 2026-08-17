// Events dispatched to the AppSettingsBloc to modify persistent settings.

import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// A base class for all app settings events.
sealed class AppSettingsEvent {
  const AppSettingsEvent();
}

/// An event that updates the app's theme mode preference.
final class UpdateTheme extends AppSettingsEvent {
  /// The new theme mode.
  final AppThemeMode themeMode;

  /// Creates an [UpdateTheme] with the given [themeMode].
  const UpdateTheme(this.themeMode);
}

/// An event that updates the weight measurement unit system.
final class UpdateMeasurementUnit extends AppSettingsEvent {
  /// The new measurement unit.
  final MeasurementUnit measurementUnit;

  /// Creates an [UpdateMeasurementUnit] with the given [measurementUnit].
  const UpdateMeasurementUnit(this.measurementUnit);
}

/// An event that updates the user's height in centimeters.
final class UpdateHeight extends AppSettingsEvent {
  /// The height in centimeters.
  final double height;

  /// Creates an [UpdateHeight] with the given [height].
  const UpdateHeight(this.height);
}

/// An event that toggles the daily notification reminder on or off.
///
/// Enabling requests OS notification permission and only schedules the
/// reminder when granted; disabling cancels the scheduled reminder.
final class ToggleNotifications extends AppSettingsEvent {
  /// Whether notifications should be enabled.
  final bool enabled;

  /// Creates a [ToggleNotifications] with the given [enabled].
  const ToggleNotifications(this.enabled);
}

/// An event that updates the time of day for the daily notification reminder.
///
/// The daily reminder is re-scheduled only while notifications are enabled.
final class UpdateNotificationTime extends AppSettingsEvent {
  /// The new notification time.
  final ({int hour, int minute}) notificationTime;

  /// Creates an [UpdateNotificationTime] with the given [notificationTime].
  const UpdateNotificationTime(this.notificationTime);
}

/// An event that sets whether the daily reminder falls back to inexact
/// Android alarm scheduling because the `SCHEDULE_EXACT_ALARM` permission was
/// revoked.
final class UpdateNotificationInexactScheduling extends AppSettingsEvent {
  /// Whether inexact alarm scheduling fallback is active.
  final bool inexact;

  /// Creates an [UpdateNotificationInexactScheduling] with the given [inexact].
  const UpdateNotificationInexactScheduling(this.inexact);
}

/// An event that updates the user's target weight in kg.
final class TargetWeightChanged extends AppSettingsEvent {
  /// The new target weight in kg (null to clear).
  final double? weight;

  /// Creates a [TargetWeightChanged] with the given [weight].
  const TargetWeightChanged(this.weight);
}

/// An event that updates the biometric lock enabled state.
final class UpdateBiometricLock extends AppSettingsEvent {
  /// Whether biometric lock should be enabled.
  final bool enabled;

  /// Creates an [UpdateBiometricLock] with the given [enabled].
  const UpdateBiometricLock(this.enabled);
}

/// An event that sets the app-wide locked state for the biometric shield.
final class SetLocked extends AppSettingsEvent {
  /// Whether the app should be locked.
  final bool locked;

  /// Creates a [SetLocked] with the given [locked].
  const SetLocked(this.locked);
}

/// An event that marks the initial onboarding wizard as completed.
final class CompleteOnboarding extends AppSettingsEvent {
  const CompleteOnboarding();
}

/// An event that sets whether biometric authentication is supported on this
/// device.
final class UpdateBiometricSupport extends AppSettingsEvent {
  /// Whether biometric auth is supported natively.
  final bool isSupported;

  /// Creates an [UpdateBiometricSupport] with the given [isSupported].
  const UpdateBiometricSupport(this.isSupported);
}

/// An event that toggles the health sync (HealthKit / Health Connect)
/// integration.
///
/// The resulting preference is persisted and restored on the next launch.
final class ToggleHealthSync extends AppSettingsEvent {
  /// Whether health sync should be enabled.
  final bool enabled;

  /// Creates a [ToggleHealthSync] with the given [enabled].
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
