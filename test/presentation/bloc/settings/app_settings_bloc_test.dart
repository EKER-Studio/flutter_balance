import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/core/services/notification_service.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockHealthService extends Mock implements HealthService {}

class MockStorage extends Mock implements Storage {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockHealthService mockHealthService;
  late MockStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 8, minute: 0));
  });

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockHealthService = MockHealthService();
    mockStorage = MockStorage();
    when(
      () => mockStorage.write(any(), any<dynamic>()),
    ).thenAnswer((_) async {});
    HydratedBloc.storage = mockStorage;
  });

  group('AppSettingsBloc', () {
    test('initial state is correct', () {
      when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
      final bloc = AppSettingsBloc(
        notificationService: mockNotificationService,
        healthService: mockHealthService,
      );
      expect(bloc.state, const AppSettingsState());
    });

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated themeMode on UpdateTheme',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const UpdateTheme(AppThemeMode.dark)),
      expect: () => [const AppSettingsState(themeMode: AppThemeMode.dark)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated measurementUnit on UpdateMeasurementUnit',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) =>
          bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial)),
      expect: () => [
        const AppSettingsState(measurementUnit: MeasurementUnit.imperial),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated height on UpdateHeight',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const UpdateHeight(180.0)),
      expect: () => [const AppSettingsState(height: 180.0)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated targetWeight on TargetWeightChanged',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const TargetWeightChanged(70.0)),
      expect: () => [const AppSettingsState(targetWeight: 70.0)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated biometric lock on UpdateBiometricLock',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const UpdateBiometricLock(true)),
      expect: () => [const AppSettingsState(isBiometricLockEnabled: true)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated locked state on SetLocked',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const SetLocked(true)),
      expect: () => [const AppSettingsState(isLocked: true)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits onboarding completed on CompleteOnboarding',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      act: (bloc) => bloc.add(const CompleteOnboarding()),
      expect: () => [const AppSettingsState(isOnboardingCompleted: true)],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits default state on ResetAppSettings',
      build: () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        return AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        );
      },
      seed: () =>
          const AppSettingsState(themeMode: AppThemeMode.dark, height: 180.0),
      act: (bloc) => bloc.add(const ResetAppSettings()),
      expect: () => [const AppSettingsState()],
    );

    group('ToggleNotifications', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'requests permissions and schedules reminder if granted',
        setUp: () {
          when(
            () => mockNotificationService.requestPermissions(),
          ).thenAnswer((_) async => true);
          when(
            () => mockNotificationService.scheduleDailyReminder(any()),
          ).thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
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
          verify(
            () => mockNotificationService.scheduleDailyReminder(
              const TimeOfDay(hour: 8, minute: 0),
            ),
          ).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits permission denied state if request fails',
        setUp: () {
          when(
            () => mockNotificationService.requestPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
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
          verifyNever(
            () => mockNotificationService.scheduleDailyReminder(any()),
          );
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'cancels reminder when disabling',
        setUp: () {
          when(
            () => mockNotificationService.cancelDailyReminder(),
          ).thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        seed: () => const AppSettingsState(notificationsEnabled: true),
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
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        act: (bloc) => bloc.add(
          const UpdateNotificationTime(TimeOfDay(hour: 9, minute: 30)),
        ),
        expect: () => [
          const AppSettingsState(
            notificationTime: TimeOfDay(hour: 9, minute: 30),
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockNotificationService.scheduleDailyReminder(any()),
          );
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits new time and schedules if notifications are enabled',
        setUp: () {
          when(
            () => mockNotificationService.scheduleDailyReminder(any()),
          ).thenAnswer((_) async {});
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        seed: () => const AppSettingsState(notificationsEnabled: true),
        act: (bloc) => bloc.add(
          const UpdateNotificationTime(TimeOfDay(hour: 9, minute: 30)),
        ),
        expect: () => [
          const AppSettingsState(
            notificationsEnabled: true,
            notificationTime: TimeOfDay(hour: 9, minute: 30),
            notificationPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockNotificationService.scheduleDailyReminder(
              const TimeOfDay(hour: 9, minute: 30),
            ),
          ).called(1);
        },
      );
    });

    group('ToggleHealthSync', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'requests permissions and enables sync if granted',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => true);
          when(
            () => mockHealthService.requestPermissions(),
          ).thenAnswer((_) async => true);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: true,
            isHealthApiAvailable: true,
            healthPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockHealthService.isHealthApiAvailable());
          verify(() => mockHealthService.requestPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits healthPermissionDenied if permission request fails',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => true);
          when(
            () => mockHealthService.requestPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: false,
            isHealthApiAvailable: true,
            healthPermissionDenied: true,
          ),
          // The transient denied flag is immediately reset so a subsequent
          // denial can be re-emitted instead of being swallowed by equatable.
          const AppSettingsState(
            isHealthSyncEnabled: false,
            isHealthApiAvailable: true,
            healthPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(() => mockHealthService.requestPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        // TEMPORARY DIAGNOSTIC: reflects the debug bypass of the availability
        // gate; restore together with the gate in app_settings_bloc.dart.
        'requests permissions even when API check reports unavailable',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
          when(
            () => mockHealthService.requestPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: false,
            isHealthApiAvailable: true,
            healthPermissionDenied: true,
          ),
          const AppSettingsState(
            isHealthSyncEnabled: false,
            isHealthApiAvailable: true,
            healthPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verify(() => mockHealthService.requestPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'disables sync and clears denied flag when toggling off',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => true);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        seed: () => const AppSettingsState(
          isHealthSyncEnabled: true,
          healthPermissionDenied: true,
        ),
        act: (bloc) => bloc.add(const ToggleHealthSync(false)),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: false,
            healthPermissionDenied: false,
          ),
        ],
        verify: (_) {
          verifyNever(() => mockHealthService.requestPermissions());
        },
      );
    });

    group('CheckHealthSyncStatus', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'updates API availability when health API is unavailable',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [const AppSettingsState(isHealthApiAvailable: false)],
        verify: (_) {
          verifyNever(() => mockHealthService.hasPermissions());
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'keeps sync enabled when permissions are still granted',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => true);
          when(
            () => mockHealthService.hasPermissions(),
          ).thenAnswer((_) async => true);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        seed: () => const AppSettingsState(
          isHealthSyncEnabled: true,
          isHealthApiAvailable: false,
        ),
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: true,
            isHealthApiAvailable: true,
          ),
        ],
        verify: (_) {
          verify(() => mockHealthService.hasPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'disables and persists sync when permissions were revoked',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => true);
          when(
            () => mockHealthService.hasPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () {
          when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
          return AppSettingsBloc(
            notificationService: mockNotificationService,
            healthService: mockHealthService,
          );
        },
        seed: () => const AppSettingsState(isHealthSyncEnabled: true),
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [
          const AppSettingsState(
            isHealthSyncEnabled: false,
            isHealthApiAvailable: true,
          ),
        ],
        verify: (_) {
          verify(() => mockHealthService.hasPermissions()).called(1);
          final writes = verify(
            () => mockStorage.write(
              'AppSettingsBloc',
              captureAny<Map<String, dynamic>>(),
            ),
          ).captured;
          expect(
            (writes.last as Map<String, dynamic>)['isHealthSyncEnabled'],
            false,
          );
        },
      );
    });

    group('fromJson / toJson', () {
      test('fromJson works correctly', () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        final bloc = AppSettingsBloc(
          notificationService: mockNotificationService,
        );
        final state = bloc.fromJson({
          'themeMode': 'dark',
          'measurementUnit': 'imperial',
          'heightCm': 175.0,
          'notificationsEnabled': true,
          'notificationTime': {'hour': 10, 'minute': 15},
          'targetWeight': 65.0,
          'isBiometricLockEnabled': true,
          'isLocked': true,
          'isOnboardingCompleted': true,
          'isHealthSyncEnabled': true,
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
            isHealthSyncEnabled: true,
          ),
        );
      });

      test('toJson works correctly', () {
        when(() => mockStorage.read('AppSettingsBloc')).thenReturn(null);
        final bloc = AppSettingsBloc(
          notificationService: mockNotificationService,
        );
        final json = bloc.toJson(
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
            notificationPermissionDenied: false, // Not serialized
            isHealthSyncEnabled: true,
            healthPermissionDenied: true, // Not serialized
          ),
        );

        expect(json, {
          'themeMode': 'dark',
          'measurementUnit': 'imperial',
          'heightCm': 175.0,
          'notificationsEnabled': true,
          'notificationTime': {'hour': 10, 'minute': 15},
          'targetWeight': 65.0,
          'isBiometricLockEnabled': true,
          'isLocked': true,
          'isOnboardingCompleted': true,
          'isHealthSyncEnabled': true,
        });
      });
    });
  });
}
