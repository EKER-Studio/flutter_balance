import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';

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
      expect(const CheckHealthSyncStatus(), isA<CheckHealthSyncStatus>());
      expect(const ResetAppSettings(), isA<ResetAppSettings>());
    });
  });
}
