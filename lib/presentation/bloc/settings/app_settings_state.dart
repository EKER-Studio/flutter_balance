import 'package:flutter/material.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';

/// Persistent app settings state.
///
/// All fields are persisted across app restarts via [HydratedBloc].
final class AppSettingsState {
  static const Object _targetWeightSentinel = Object();

  /// The selected theme mode.
  final AppThemeMode themeMode;

  /// The weight measurement unit system.
  final MeasurementUnit measurementUnit;

  /// The user's height in centimeters (default: 170).
  final double height;

  /// Whether daily notification reminders are enabled.
  final bool notificationsEnabled;

  /// The time of day for the daily reminder (default: 08:00).
  final TimeOfDay notificationTime;

  /// The user's target weight in kg (null means no target set).
  final double? targetWeight;

  /// Whether biometric lock is enabled for app unlock.
  final bool isBiometricLockEnabled;

  /// Whether the app is currently locked behind the biometric shield.
  final bool isLocked;

  /// Creates [AppSettingsState] with the given parameters.
  const AppSettingsState({
    this.themeMode = AppThemeMode.system,
    this.measurementUnit = MeasurementUnit.metric,
    this.height = 170.0,
    this.notificationsEnabled = true,
    this.notificationTime = const TimeOfDay(hour: 8, minute: 0),
    this.targetWeight,
    this.isBiometricLockEnabled = false,
    this.isLocked = false,
  });

  /// Creates a copy of this state with the given fields replaced.
  AppSettingsState copyWith({
    AppThemeMode? themeMode,
    MeasurementUnit? measurementUnit,
    double? height,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
    Object? targetWeight = _targetWeightSentinel,
    bool? isBiometricLockEnabled,
    bool? isLocked,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      height: height ?? this.height,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      targetWeight: targetWeight == _targetWeightSentinel
          ? this.targetWeight
          : targetWeight as double?,
      isBiometricLockEnabled:
          isBiometricLockEnabled ?? this.isBiometricLockEnabled,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  /// Deserializes [AppSettingsState] from a JSON map.
  factory AppSettingsState.fromJson(Map<String, dynamic> json) {
    final heightValue = json['heightCm'] ?? json['height'];
    final biometricLockEnabled =
        json['isBiometricLockEnabled'] as bool? ?? false;

    return AppSettingsState(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      measurementUnit: MeasurementUnit.values.firstWhere(
        (e) => e.name == json['measurementUnit'],
        orElse: () => MeasurementUnit.metric,
      ),
      height: (heightValue as num?)?.toDouble() ?? 170.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      notificationTime: json['notificationTime'] != null
          ? TimeOfDay(
              hour: json['notificationTime']['hour'] as int,
              minute: json['notificationTime']['minute'] as int,
            )
          : const TimeOfDay(hour: 8, minute: 0),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      isBiometricLockEnabled: biometricLockEnabled,
      isLocked: biometricLockEnabled
          ? true
          : (json['isLocked'] as bool? ?? false),
    );
  }

  /// Serializes [AppSettingsState] into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'measurementUnit': measurementUnit.name,
      'heightCm': height,
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': {
        'hour': notificationTime.hour,
        'minute': notificationTime.minute,
      },
      'targetWeight': targetWeight,
      'isBiometricLockEnabled': isBiometricLockEnabled,
    };
  }
}

/// Helper methods for BMI-related app settings behavior.
extension AppSettingsX on AppSettingsState {
  /// Calculates the user's BMI from the current configured height and a weight.
  double calculateBmi(double currentWeightKg) {
    if (height <= 0) {
      return 0.0;
    }

    final heightInMeters = height / 100;
    return currentWeightKg / (heightInMeters * heightInMeters);
  }

  /// Maps a BMI value to a structured category.
  BmiCategory getBmiCategory(double bmi) => BmiCategory.fromBmi(bmi);
}
