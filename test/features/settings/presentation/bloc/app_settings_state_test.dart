import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';

void main() {
  group('AppSettingsState Unit Tests', () {
    test('default constructor initializes standard defaults', () {
      const state = AppSettingsState();

      expect(state.themeMode, AppThemeMode.system);
      expect(state.firstDayOfWeek, FirstDayOfWeek.system);
      expect(state.measurementUnit, MeasurementUnit.metric);
      expect(state.height, isNull);
      expect(state.notificationsEnabled, isFalse);
      expect(state.notificationTime, (hour: 8, minute: 0));
      expect(state.targetWeight, isNull);
      expect(state.weightGoalMode, WeightGoalMode.lose);
      expect(state.isBiometricLockEnabled, isFalse);
      expect(state.isLocked, isFalse);
      expect(state.isOnboardingCompleted, isFalse);
      expect(state.isHealthSyncEnabled, isFalse);
      expect(state.weeklyPaceWindowDays, 30);
    });

    test(
      'copyWith modifies specified fields and supports nulling targetWeight and height',
      () {
        const initial = AppSettingsState(
          height: 180.0,
          targetWeight: 75.0,
          themeMode: AppThemeMode.light,
        );

        final updated = initial.copyWith(
          height: null,
          targetWeight: null,
          themeMode: AppThemeMode.dark,
        );

        expect(updated.height, isNull);
        expect(updated.targetWeight, isNull);
        expect(updated.themeMode, AppThemeMode.dark);
      },
    );

    test('toJson and fromJson perform complete roundtrip serialization', () {
      final syncTime = DateTime(2026, 7, 1, 14, 30);
      final state = AppSettingsState(
        themeMode: AppThemeMode.dark,
        firstDayOfWeek: FirstDayOfWeek.monday,
        measurementUnit: MeasurementUnit.imperial,
        height: 175.0,
        notificationsEnabled: true,
        notificationTime: (hour: 9, minute: 15),
        targetWeight: 68.0,
        weightGoalMode: WeightGoalMode.maintain,
        isBiometricLockEnabled: false,
        isLocked: false,
        isOnboardingCompleted: true,
        isHealthSyncEnabled: true,
        lastHealthSyncTimestamp: syncTime,
        weeklyPaceWindowDays: 14,
      );

      final json = state.toJson();
      final restored = AppSettingsState.fromJson(json);

      expect(restored.themeMode, AppThemeMode.dark);
      expect(restored.firstDayOfWeek, FirstDayOfWeek.monday);
      expect(restored.measurementUnit, MeasurementUnit.imperial);
      expect(restored.height, 175.0);
      expect(restored.notificationsEnabled, isTrue);
      expect(restored.notificationTime, (hour: 9, minute: 15));
      expect(restored.targetWeight, 68.0);
      expect(restored.weightGoalMode, WeightGoalMode.maintain);
      expect(restored.isBiometricLockEnabled, isFalse);
      expect(restored.isLocked, isFalse);
      expect(restored.isOnboardingCompleted, isTrue);
      expect(restored.isHealthSyncEnabled, isTrue);
      expect(restored.lastHealthSyncTimestamp, syncTime);
      expect(restored.weeklyPaceWindowDays, 14);
    });

    test(
      'calculateBmi returns 0.0 when height is null and accurate BMI when set',
      () {
        const stateWithoutHeight = AppSettingsState(height: null);
        expect(stateWithoutHeight.calculateBmi(70.0), 0.0);

        const stateWithHeight = AppSettingsState(height: 180.0);
        final bmi = stateWithHeight.calculateBmi(72.9);
        expect(bmi, closeTo(22.5, 0.1));
        expect(stateWithHeight.getBmiCategory(bmi), BmiCategory.normal);
      },
    );
  });
}
