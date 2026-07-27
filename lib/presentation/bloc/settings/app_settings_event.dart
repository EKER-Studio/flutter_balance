import 'package:flutter/material.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';

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

/// Legacy target-weight event retained for existing callers.
final class UpdateTargetWeight extends AppSettingsEvent {
  /// The new target weight in kg (null to clear).
  final double? targetWeight;

  /// Creates [UpdateTargetWeight] with the given [targetWeight].
  const UpdateTargetWeight(this.targetWeight);
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
