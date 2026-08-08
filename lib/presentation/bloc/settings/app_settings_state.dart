import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:balance/presentation/bloc/settings/app_theme_mode.dart';
import 'package:balance/presentation/bloc/settings/bmi_category.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// Persistent app settings state.
///
/// All fields are persisted across app restarts via [HydratedBloc].
final class AppSettingsState extends Equatable {
  static const Object _targetWeightSentinel = Object();
  static const Object _heightSentinel = Object();

  /// Minimum valid height in centimeters, inclusive.
  static const double minHeightCm = 50.0;

  /// Maximum valid height in centimeters, inclusive.
  static const double maxHeightCm = 250.0;

  /// The selected theme mode.
  final AppThemeMode themeMode;

  /// The weight measurement unit system.
  final MeasurementUnit measurementUnit;

  /// The user's height in centimeters. `null` means the user has not set a height yet.
  final double? height;

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

  /// Whether the user has completed the initial onboarding wizard.
  final bool isOnboardingCompleted;

  /// Transient flag set when the last notification permission request was
  /// denied. Consumed by the UI to surface a permission-required message;
  /// never persisted and reset by any subsequent notification-related event.
  final bool notificationPermissionDenied;

  /// Transient flag indicating if the device hardware supports biometrics.
  /// Not persisted; evaluated freshly on each app launch.
  final bool isBiometricSupported;

  /// Whether health sync (HealthKit / Health Connect) is activated by the user.
  /// Persisted across app restarts; see [isHealthApiAvailable] for platform
  /// support and [healthPermissionDenied] for authorization failures.
  final bool isHealthSyncEnabled;

  /// Whether the OS supports HealthKit (iOS) / Health Connect (Android).
  /// Not persisted; evaluated freshly on each app launch.
  final bool isHealthApiAvailable;

  /// Transient flag set when the last health permission request was denied.
  /// Consumed by the UI to surface a permission-required message;
  /// never persisted and reset by any subsequent health-related event.
  final bool healthPermissionDenied;

  /// Creates [AppSettingsState] with the given parameters.
  const AppSettingsState({
    this.themeMode = AppThemeMode.system,
    this.measurementUnit = MeasurementUnit.metric,
    this.height,
    this.notificationsEnabled = false,
    this.notificationTime = const TimeOfDay(hour: 8, minute: 0),
    this.targetWeight,
    this.isBiometricLockEnabled = false,
    this.isLocked = false,
    this.isOnboardingCompleted = false,
    this.notificationPermissionDenied = false,
    this.isBiometricSupported = true,
    this.isHealthSyncEnabled = false,
    this.isHealthApiAvailable = true,
    this.healthPermissionDenied = false,
  });

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// To explicitly clear the height back to `null`, pass `null` as [height]
  /// (the sentinel default keeps the current value).
  AppSettingsState copyWith({
    AppThemeMode? themeMode,
    MeasurementUnit? measurementUnit,
    Object? height = _heightSentinel,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
    Object? targetWeight = _targetWeightSentinel,
    bool? isBiometricLockEnabled,
    bool? isLocked,
    bool? isOnboardingCompleted,
    bool? notificationPermissionDenied,
    bool? isBiometricSupported,
    bool? isHealthSyncEnabled,
    bool? isHealthApiAvailable,
    bool? healthPermissionDenied,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      height: height == _heightSentinel ? this.height : height as double?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      targetWeight: targetWeight == _targetWeightSentinel
          ? this.targetWeight
          : targetWeight as double?,
      isBiometricLockEnabled:
          isBiometricLockEnabled ?? this.isBiometricLockEnabled,
      isLocked: isLocked ?? this.isLocked,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      notificationPermissionDenied:
          notificationPermissionDenied ?? this.notificationPermissionDenied,
      isBiometricSupported: isBiometricSupported ?? this.isBiometricSupported,
      isHealthSyncEnabled: isHealthSyncEnabled ?? this.isHealthSyncEnabled,
      isHealthApiAvailable: isHealthApiAvailable ?? this.isHealthApiAvailable,
      healthPermissionDenied:
          healthPermissionDenied ?? this.healthPermissionDenied,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    measurementUnit,
    height,
    notificationsEnabled,
    notificationTime,
    targetWeight,
    isBiometricLockEnabled,
    isLocked,
    isOnboardingCompleted,
    notificationPermissionDenied,
    isBiometricSupported,
    isHealthSyncEnabled,
    isHealthApiAvailable,
    healthPermissionDenied,
  ];

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
      height: (heightValue as num?)?.toDouble(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      notificationTime: (() {
        final notifTime = json['notificationTime'];
        if (notifTime == null || notifTime is! Map<String, dynamic>) {
          return const TimeOfDay(hour: 8, minute: 0);
        }
        final hour = notifTime['hour'];
        final minute = notifTime['minute'];
        if (hour is int && minute is int) {
          return TimeOfDay(hour: hour, minute: minute);
        }
        return const TimeOfDay(hour: 8, minute: 0);
      })(),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      isBiometricLockEnabled: biometricLockEnabled,
      isLocked: biometricLockEnabled
          ? true
          : (json['isLocked'] as bool? ?? false),
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      isHealthSyncEnabled: json['isHealthSyncEnabled'] as bool? ?? false,
      // Transient flag: never restored from storage.
      notificationPermissionDenied: false,
      isBiometricSupported: true,
      // Transient flags: never restored from storage.
      isHealthApiAvailable: true,
      healthPermissionDenied: false,
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
      'isLocked': isLocked,
      'isOnboardingCompleted': isOnboardingCompleted,
      'isHealthSyncEnabled': isHealthSyncEnabled,
    };
  }
}

/// Helper methods for BMI-related app settings behavior.
extension AppSettingsX on AppSettingsState {
  /// Calculates the user's BMI from the current configured height and a weight.
  ///
  /// Returns `0.0` when height has not been set yet.
  double calculateBmi(double currentWeightKg) {
    final h = height;
    if (h == null || h <= 0) {
      return 0.0;
    }

    final heightInMeters = h / 100;
    return currentWeightKg / (heightInMeters * heightInMeters);
  }

  /// Maps a BMI value to a structured category.
  BmiCategory getBmiCategory(double bmi) => BmiCategory.fromBmi(bmi);
}
