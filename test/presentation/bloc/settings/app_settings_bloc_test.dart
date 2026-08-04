import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_theme_mode.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockStorage extends Mock implements Storage {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 8, minute: 0));
  });

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockStorage = MockStorage();
    when(() => mockStorage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = mockStorage;
  });

  group('AppSettingsBloc', () {
    test('initial state is correct', () {
      when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
      final bloc = AppSettingsBloc(notificationService: mockNotificationService);
      expect(bloc.state, const AppSettingsState());
    });

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated themeMode on UpdateTheme',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const UpdateTheme(AppThemeMode.dark)),
      expect: () => [
        const AppSettingsState(themeMode: AppThemeMode.dark),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated measurementUnit on UpdateMeasurementUnit',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial)),
      expect: () => [
        const AppSettingsState(measurementUnit: MeasurementUnit.imperial),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated height on UpdateHeight',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const UpdateHeight(180.0)),
      expect: () => [
        const AppSettingsState(height: 180.0),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated targetWeight on TargetWeightChanged',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const TargetWeightChanged(70.0)),
      expect: () => [
        const AppSettingsState(targetWeight: 70.0),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated biometric lock on UpdateBiometricLock',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const UpdateBiometricLock(true)),
      expect: () => [
        const AppSettingsState(isBiometricLockEnabled: true),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated locked state on SetLocked',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const SetLocked(true)),
      expect: () => [
        const AppSettingsState(isLocked: true),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits onboarding completed on CompleteOnboarding',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      act: (bloc) => bloc.add(const CompleteOnboarding()),
      expect: () => [
        const AppSettingsState(isOnboardingCompleted: true),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits default state on ResetAppSettings',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(notificationService: mockNotificationService);
      },
      seed: () => const AppSettingsState(
        themeMode: AppThemeMode.dark,
        height: 180.0,
      ),
      act: (bloc) => bloc.add(const ResetAppSettings()),
      expect: () => [
        const AppSettingsState(),
      ],
    );

    group('ToggleNotifications', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'requests permissions and schedules reminder if granted',
        setUp: () {
          when(() => mockNotificationService.requestPermissions())
              .thenAnswer((_) async => true);
          when(() => mockNotificationService.scheduleDailyReminder(any()))
              .thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(notificationService: mockNotificationService);
        },
        act: (bloc) => bloc.add(const ToggleNotifications(true)),
        expect: () => [
          const AppSettingsState(
            notificationsEnabled: true,
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(() => mockNotificationService.requestPermissions()).called(1);
          verify(() => mockNotificationService.scheduleDailyReminder(
              const TimeOfDay(hour: 8, minute: 0))).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits permission denied state if request fails',
        setUp: () {
          when(() => mockNotificationService.requestPermissions())
              .thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(notificationService: mockNotificationService);
        },
        act: (bloc) => bloc.add(const ToggleNotifications(true)),
        expect: () => [
          const AppSettingsState(
            notificationsEnabled: false,
            notificationPermissionDenied: true,
          ),
        ],
        verify: (_) {
          verify(() => mockNotificationService.requestPermissions()).called(1);
          verifyNever(() => mockNotificationService.scheduleDailyReminder(any()));
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'cancels reminder when disabling',
        setUp: () {
          when(() => mockNotificationService.cancelDailyReminder())
              .thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(notificationService: mockNotificationService);
        },
        seed: () => const AppSettingsState(
          notificationsEnabled: true,
        ),
        act: (bloc) => bloc.add(const ToggleNotifications(false)),
        expect: () => [
          const AppSettingsState(
            notificationsEnabled: false,
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(() => mockNotificationService.cancelDailyReminder()).called(1);
        },
      );
    });

    group('UpdateNotificationTime', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits new time but does not schedule if notifications are disabled',
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(notificationService: mockNotificationService);
        },
        act: (bloc) => bloc.add(const UpdateNotificationTime(TimeOfDay(hour: 9, minute: 30))),
        expect: () => [
          const AppSettingsState(
            notificationTime: TimeOfDay(hour: 9, minute: 30),
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockNotificationService.scheduleDailyReminder(any()));
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits new time and schedules if notifications are enabled',
        setUp: () {
          when(() => mockNotificationService.scheduleDailyReminder(any()))
              .thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(notificationService: mockNotificationService);
        },
        seed: () => const AppSettingsState(
          notificationsEnabled: true,
        ),
        act: (bloc) => bloc.add(const UpdateNotificationTime(TimeOfDay(hour: 9, minute: 30))),
        expect: () => [
          const AppSettingsState(
            notificationsEnabled: true,
            notificationTime: TimeOfDay(hour: 9, minute: 30),
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(() => mockNotificationService.scheduleDailyReminder(
              const TimeOfDay(hour: 9, minute: 30))).called(1);
        },
      );
    });

    group('fromJson / toJson', () {
      test('fromJson works correctly', () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        final bloc = AppSettingsBloc(notificationService: mockNotificationService);
        final state = bloc.fromJson({
          'themeMode': 'dark',
          'measurementUnit': 'imperial',
          'heightCm': 175.0,
          'notificationsEnabled': true,
          'notificationTime': {
            'hour': 10,
            'minute': 15,
          },
          'targetWeight': 65.0,
          'isBiometricLockEnabled': true,
          'isLocked': true,
          'isOnboardingCompleted': true,
        });

        expect(
          state,
          const AppSettingsState(
            themeMode: AppThemeMode.dark,
            measurementUnit: MeasurementUnit.imperial,
            height: 175.0,
            notificationsEnabled: true,
            notificationTime: TimeOfDay(hour: 10, minute: 15),
            targetWeight: 65.0,
            isBiometricLockEnabled: true,
            isLocked: true,
            isOnboardingCompleted: true,
            notificationPermissionDenied: false,
          ),
        );
      });

      test('toJson works correctly', () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        final bloc = AppSettingsBloc(notificationService: mockNotificationService);
        final json = bloc.toJson(const AppSettingsState(
          themeMode: AppThemeMode.dark,
          measurementUnit: MeasurementUnit.imperial,
          height: 175.0,
          notificationsEnabled: true,
          notificationTime: TimeOfDay(hour: 10, minute: 15),
          targetWeight: 65.0,
          isBiometricLockEnabled: true,
          isLocked: true,
          isOnboardingCompleted: true,
          notificationPermissionDenied: false, // Not serialized
        ));

        expect(json, {
          'themeMode': 'dark',
          'measurementUnit': 'imperial',
          'heightCm': 175.0,
          'notificationsEnabled': true,
          'notificationTime': {
            'hour': 10,
            'minute': 15,
          },
          'targetWeight': 65.0,
          'isBiometricLockEnabled': true,
          'isLocked': true,
          'isOnboardingCompleted': true,
        });
      });
    });
  });
}
