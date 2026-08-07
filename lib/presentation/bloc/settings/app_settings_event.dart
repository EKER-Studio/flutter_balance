import 'package:flutter/material.dart';
import 'package:balance/presentation/bloc/settings/app_theme_mode.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// Base class for all app settings events.
sealed class AppSettingsEvent {
  const AppSettingsEvent();
}

/// Updates the app's theme mode preference.
final class UpdateTheme extends AppSettingsEvent {
  /// The new theme mode.
  final AppThemeMode themeMode;

  /// Creates [UpdateTheme] with the given [themeMode].
  const UpdateTheme(this.themeMode);
}

/// Updates the weight measurement unit system.
final class UpdateMeasurementUnit extends AppSettingsEvent {
  /// The new measurement unit.
  final MeasurementUnit measurementUnit;

  /// Creates [UpdateMeasurementUnit] with the given [measurementUnit].
  const UpdateMeasurementUnit(this.measurementUnit);
}

/// Updates the user's height in centimeters.
final class UpdateHeight extends AppSettingsEvent {
  /// Height in centimeters.
  final double height;

  /// Creates [UpdateHeight] with the given [height].
  const UpdateHeight(this.height);
}

/// Toggles the daily notification reminder on or off.
final class ToggleNotifications extends AppSettingsEvent {
  /// Whether notifications should be enabled.
  final bool enabled;

  /// Creates [ToggleNotifications] with the given [enabled].
  const ToggleNotifications(this.enabled);
}

/// Updates the time of day for the daily notification reminder.
final class UpdateNotificationTime extends AppSettingsEvent {
  /// The new notification time.
  final TimeOfDay notificationTime;

  /// Creates [UpdateNotificationTime] with the given [notificationTime].
  const UpdateNotificationTime(this.notificationTime);
}

/// Updates the user's target weight in kg.
final class TargetWeightChanged extends AppSettingsEvent {
  /// The new target weight in kg (null to clear).
  final double? weight;

  /// Creates [TargetWeightChanged] with the given [weight].
  const TargetWeightChanged(this.weight);
}

/// Updates the biometric lock enabled state.
final class UpdateBiometricLock extends AppSettingsEvent {
  /// Whether biometric lock should be enabled.
  final bool enabled;

  /// Creates [UpdateBiometricLock] with the given [enabled].
  const UpdateBiometricLock(this.enabled);
}

/// Sets the app-wide locked state for the biometric shield.
final class SetLocked extends AppSettingsEvent {
  /// Whether the app should be locked.
  final bool locked;

  /// Creates [SetLocked] with the given [locked].
  const SetLocked(this.locked);
}

/// Marks the initial onboarding wizard as completed.
final class CompleteOnboarding extends AppSettingsEvent {
  /// Creates [CompleteOnboarding].
  const CompleteOnboarding();
}

/// Sets whether biometric authentication is supported on this device.
final class UpdateBiometricSupport extends AppSettingsEvent {
  /// Whether biometric auth is supported natively.
  final bool isSupported;

  /// Creates [UpdateBiometricSupport] with the given [isSupported].
  const UpdateBiometricSupport(this.isSupported);
}

/// Toggles the health sync (HealthKit / Health Connect) integration.
final class ToggleHealthSync extends AppSettingsEvent {
  /// Whether health sync should be enabled.
  final bool enabled;

  /// Creates [ToggleHealthSync] with the given [enabled].
  const ToggleHealthSync(this.enabled);
}

/// Re-evaluates health API availability and permission grants on app start.
///
/// If health sync is enabled but the native permissions were revoked, the
/// sync flag is automatically disabled and persisted.
final class CheckHealthSyncStatus extends AppSettingsEvent {
  /// Creates [CheckHealthSyncStatus].
  const CheckHealthSyncStatus();
}

/// Resets all application settings to factory default values.
final class ResetAppSettings extends AppSettingsEvent {
  /// Creates [ResetAppSettings].
  const ResetAppSettings();
}
