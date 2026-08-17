// Immutable application settings state persisted across restarts.

import 'package:equatable/equatable.dart';

import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// A persistent app settings state.
///
/// All fields are persisted across app restarts via `HydratedBloc`.
final class AppSettingsState extends Equatable {
  static const Object _targetWeightSentinel = Object();
  static const Object _heightSentinel = Object();

  /// Minimum valid height in centimeters, inclusive.
  static const double minHeightCm = 50.0;

  /// Maximum valid height in centimeters, inclusive.
  static const double maxHeightCm = 250.0;

  /// The selected theme mode (default: [AppThemeMode.system]).
  final AppThemeMode themeMode;

  /// The weight measurement unit system (default: [MeasurementUnit.metric]).
  final MeasurementUnit measurementUnit;

  /// The user's height in centimeters.
  ///
  /// A value of `null` means the user has not set a height yet. When set, the
  /// UI restricts the value to the inclusive [minHeightCm]–[maxHeightCm] range.
  final double? height;

  /// Whether daily notification reminders are enabled (default: off).
  final bool notificationsEnabled;

  /// The time of day for the daily reminder (default: 08:00).
  final ({int hour, int minute}) notificationTime;

  /// The user's target weight in kg (`null` means no target is set).
  ///
  /// Set from the profile screen and used for progress calculations.
  final double? targetWeight;

  /// Whether biometric lock is enabled for app unlock (default: off).
  final bool isBiometricLockEnabled;

  /// Whether the app is currently locked behind the biometric shield.
  ///
  /// When biometric lock is enabled, the app starts in the locked state.
  final bool isLocked;

  /// Whether the user has completed the initial onboarding wizard (default:
  /// false).
  final bool isOnboardingCompleted;

  /// Whether the last notification permission request was denied.
  ///
  /// Transient: consumed by the UI to surface a permission-required message,
  /// never persisted, and reset by any subsequent notification-related event.
  final bool notificationPermissionDenied;

  /// Whether the daily reminder currently falls back to inexact Android alarm
  /// scheduling because the `SCHEDULE_EXACT_ALARM` permission was revoked.
  ///
  /// Transient: re-evaluated on each app launch and whenever a reminder is
  /// (re)scheduled, never persisted.
  final bool notificationInexactScheduling;

  /// Whether the device hardware supports biometrics.
  ///
  /// Not persisted; evaluated freshly on each app launch.
  final bool isBiometricSupported;

  /// Whether health sync (HealthKit / Health Connect) is activated by the user
  /// (default: off).
  ///
  /// Persisted across app restarts; see [isHealthApiAvailable] for platform
  /// support and [healthPermissionDenied] for authorization failures.
  final bool isHealthSyncEnabled;

  /// Whether the OS supports HealthKit (iOS) / Health Connect (Android).
  /// Not persisted; evaluated freshly on each app launch.
  final bool isHealthApiAvailable;

  /// Whether the last health permission request was denied.
  ///
  /// Transient: consumed by the UI to surface a permission-required message,
  /// never persisted, and reset by any subsequent health-related event.
  final bool healthPermissionDenied;

  /// Creates an [AppSettingsState] with the given parameters.
  const AppSettingsState({
    this.themeMode = AppThemeMode.system,
    this.measurementUnit = MeasurementUnit.metric,
    this.height,
    this.notificationsEnabled = false,
    this.notificationTime = const (hour: 8, minute: 0),
    this.targetWeight,
    this.isBiometricLockEnabled = false,
    this.isLocked = false,
    this.isOnboardingCompleted = false,
    this.notificationPermissionDenied = false,
    this.notificationInexactScheduling = false,
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
    ({int hour, int minute})? notificationTime,
    Object? targetWeight = _targetWeightSentinel,
    bool? isBiometricLockEnabled,
    bool? isLocked,
    bool? isOnboardingCompleted,
    bool? notificationPermissionDenied,
    bool? notificationInexactScheduling,
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
      notificationInexactScheduling:
          notificationInexactScheduling ?? this.notificationInexactScheduling,
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
    notificationInexactScheduling,
    isBiometricSupported,
    isHealthSyncEnabled,
    isHealthApiAvailable,
    healthPermissionDenied,
  ];

  /// Deserializes an [AppSettingsState] from a JSON map.
  ///
  /// Reads the legacy `height` key as a fallback for `heightCm`; unknown enum
  /// names and transient flags fall back to their defaults.
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
          return const (hour: 8, minute: 0);
        }
        final hour = notifTime['hour'];
        final minute = notifTime['minute'];
        if (hour is int && minute is int) {
          return (hour: hour, minute: minute);
        }
        return const (hour: 8, minute: 0);
      })(),
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      isBiometricLockEnabled: biometricLockEnabled,
      isLocked: biometricLockEnabled
          ? true
          : (json['isLocked'] as bool? ?? false),
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      isHealthSyncEnabled: json['isHealthSyncEnabled'] as bool? ?? false,
      // Transient flags: never restored from storage.
      notificationPermissionDenied: false,
      notificationInexactScheduling: false,
      isBiometricSupported: true,
      // Transient flags: never restored from storage.
      isHealthApiAvailable: true,
      healthPermissionDenied: false,
    );
  }

  ///// Serializes an [AppSettingsState] into a JSON map.
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

/// An extension containing helper methods for BMI-related app settings behavior.
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
