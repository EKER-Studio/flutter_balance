import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';

void main() {
  group('AppSettingsEvent construction', () {
    test('event instances carry their configured values', () {
      expect(
        UpdateTheme(AppThemeMode.dark).themeMode,
        AppThemeMode.dark,
      );
      expect(
        UpdateMeasurementUnit(MeasurementUnit.imperial).measurementUnit,
        MeasurementUnit.imperial,
      );
      expect(UpdateHeight(175.0).height, 175.0);
      expect(ToggleNotifications(true).enabled, isTrue);
      expect(
        UpdateNotificationTime((hour: 9, minute: 30)).notificationTime,
        (hour: 9, minute: 30),
      );
      expect(
        UpdateNotificationInexactScheduling(true).inexact,
        isTrue,
      );
      expect(TargetWeightChanged(80).weight, 80);
      expect(TargetWeightChanged(null).weight, isNull);
      expect(UpdateBiometricLock(true).enabled, isTrue);
      expect(SetLocked(true).locked, isTrue);
      expect(UpdateBiometricSupport(false).isSupported, isFalse);
      expect(ToggleHealthSync(true).enabled, isTrue);
    });

    test('flag-less events are constructible', () {
      expect(CompleteOnboarding(), isA<CompleteOnboarding>());
      expect(CheckHealthSyncStatus(), isA<CheckHealthSyncStatus>());
      expect(ResetAppSettings(), isA<ResetAppSettings>());
    });
  });
}