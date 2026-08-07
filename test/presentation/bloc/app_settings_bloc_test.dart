import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/services/notification_service.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/bmi_category.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/bloc/settings/app_settings_state.dart';
import 'package:balance/presentation/bloc/settings/app_theme_mode.dart';
import 'package:balance/core/models/measurement_unit.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockNotificationService extends Mock implements NotificationService {}

class MockHealthService extends Mock implements HealthService {}

void main() {
  late MockHydratedStorage storage;
  late MockNotificationService mockNotificationService;
  late MockHealthService mockHealthService;

  setUpAll(() {
    registerFallbackValue(const TimeOfDay(hour: 8, minute: 0));
  });

  setUp(() {
    storage = MockHydratedStorage();
    mockNotificationService = MockNotificationService();
    mockHealthService = MockHealthService();

    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(
      () => mockHealthService.isHealthApiAvailable(),
    ).thenAnswer((_) async => true);
    when(
      () => mockHealthService.requestPermissions(),
    ).thenAnswer((_) async => true);
    when(
      () => mockHealthService.hasPermissions(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationService.requestPermissions(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationService.scheduleDailyReminder(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelDailyReminder(),
    ).thenAnswer((_) async {});
  });

  group('AppSettingsBloc', () {
    test('initial state has correct defaults', () {
      final bloc = AppSettingsBloc(
        notificationService: mockNotificationService,
      );
      expect(bloc.state.themeMode, AppThemeMode.system);
      expect(bloc.state.measurementUnit, MeasurementUnit.metric);
      expect(bloc.state.height, isNull);
      expect(bloc.state.notificationsEnabled, false);
      expect(bloc.state.notificationTime, const TimeOfDay(hour: 8, minute: 0));
      expect(bloc.state.isLocked, false);
      expect(bloc.state.isOnboardingCompleted, false);
      expect(bloc.state.isHealthSyncEnabled, false);
      expect(bloc.state.isHealthApiAvailable, true);
      expect(bloc.state.healthPermissionDenied, false);
    });

    group('AppSettingsX', () {
      test('calculates BMI from the configured height in centimeters', () {
        const state = AppSettingsState(height: 180.0);

        expect(state.calculateBmi(75.0), closeTo(23.15, 0.01));
      });

      test('returns 0.0 for invalid height values', () {
        const state = AppSettingsState(height: 0.0);

        expect(state.calculateBmi(75.0), equals(0.0));
      });

      test('maps BMI values to the expected category', () {
        const state = AppSettingsState();

        expect(state.getBmiCategory(17.0), BmiCategory.underweight);
        expect(state.getBmiCategory(22.0), BmiCategory.normal);
        expect(state.getBmiCategory(27.0), BmiCategory.overweight);
        expect(state.getBmiCategory(31.0), BmiCategory.obese);
      });
    });

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated state on UpdateTheme',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const UpdateTheme(AppThemeMode.dark)),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.themeMode,
          'themeMode',
          AppThemeMode.dark,
        ),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated state on UpdateMeasurementUnit',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) =>
          bloc.add(const UpdateMeasurementUnit(MeasurementUnit.imperial)),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.measurementUnit,
          'measurementUnit',
          MeasurementUnit.imperial,
        ),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated state on UpdateHeight',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const UpdateHeight(180.0)),
      expect: () => [
        isA<AppSettingsState>().having((s) => s.height, 'height', 180.0),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits notificationsEnabled true and schedules reminder on ToggleNotifications(true) when granted',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const ToggleNotifications(true)),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.notificationsEnabled,
          'notificationsEnabled',
          true,
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
      'emits notificationsEnabled false and denied flag on ToggleNotifications(true) when permission denied',
      setUp: () {
        when(
          () => mockNotificationService.requestPermissions(),
        ).thenAnswer((_) async => false);
      },
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const ToggleNotifications(true)),
      expect: () => [
        isA<AppSettingsState>()
            .having(
              (s) => s.notificationsEnabled,
              'notificationsEnabled',
              false,
            )
            .having(
              (s) => s.notificationPermissionDenied,
              'notificationPermissionDenied',
              true,
            ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.requestPermissions()).called(1);
        verifyNever(() => mockNotificationService.scheduleDailyReminder(any()));
      },
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'clears the denied flag on ToggleNotifications(false)',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(
        notificationsEnabled: false,
        notificationPermissionDenied: true,
      ),
      act: (bloc) => bloc.add(const ToggleNotifications(false)),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.notificationPermissionDenied,
          'notificationPermissionDenied',
          false,
        ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.cancelDailyReminder()).called(1);
      },
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'clears the denied flag on UpdateNotificationTime',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(notificationPermissionDenied: true),
      act: (bloc) => bloc.add(
        const UpdateNotificationTime(TimeOfDay(hour: 12, minute: 30)),
      ),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.notificationPermissionDenied,
          'notificationPermissionDenied',
          false,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockNotificationService.scheduleDailyReminder(any()));
      },
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits notificationsEnabled false and cancels reminder on ToggleNotifications(false)',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(notificationsEnabled: true),
      act: (bloc) => bloc.add(const ToggleNotifications(false)),
      expect: () => [
        isA<AppSettingsState>()
            .having(
              (s) => s.notificationsEnabled,
              'notificationsEnabled',
              false,
            )
            .having(
              (s) => s.notificationPermissionDenied,
              'notificationPermissionDenied',
              false,
            ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.cancelDailyReminder()).called(1);
      },
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated state and reschedules when enabled on UpdateNotificationTime',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(notificationsEnabled: true),
      act: (bloc) => bloc.add(
        const UpdateNotificationTime(TimeOfDay(hour: 12, minute: 30)),
      ),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.notificationTime,
          'notificationTime',
          const TimeOfDay(hour: 12, minute: 30),
        ),
      ],
      verify: (_) {
        verify(
          () => mockNotificationService.scheduleDailyReminder(
            const TimeOfDay(hour: 12, minute: 30),
          ),
        ).called(1);
      },
    );

    group('ToggleHealthSync', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'requests permissions, enables sync, and persists the enabled flag',
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                true,
              )
              .having(
                (s) => s.isHealthApiAvailable,
                'isHealthApiAvailable',
                true,
              )
              .having(
                (s) => s.healthPermissionDenied,
                'healthPermissionDenied',
                false,
              ),
        ],
        verify: (_) {
          verify(() => mockHealthService.isHealthApiAvailable()).called(1);
          verify(() => mockHealthService.requestPermissions()).called(1);
          final writes = verify(
            () => storage.write(
              'AppSettingsBloc',
              captureAny<Map<String, dynamic>>(),
            ),
          ).captured;
          expect(
            (writes.last as Map<String, dynamic>)['isHealthSyncEnabled'],
            true,
          );
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'emits healthPermissionDenied and keeps sync disabled when '
        'permission request is denied',
        setUp: () {
          when(
            () => mockHealthService.requestPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                false,
              )
              .having(
                (s) => s.healthPermissionDenied,
                'healthPermissionDenied',
                true,
              ),
        ],
        verify: (_) {
          verify(() => mockHealthService.requestPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'flags the health API as unavailable when the platform lacks it',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
        },
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        act: (bloc) => bloc.add(const ToggleHealthSync(true)),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                false,
              )
              .having(
                (s) => s.isHealthApiAvailable,
                'isHealthApiAvailable',
                false,
              ),
        ],
        verify: (_) {
          verifyNever(() => mockHealthService.requestPermissions());
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'disables sync and clears transient flags on ToggleHealthSync(false)',
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        seed: () => const AppSettingsState(
          isHealthSyncEnabled: true,
          healthPermissionDenied: true,
        ),
        act: (bloc) => bloc.add(const ToggleHealthSync(false)),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                false,
              )
              .having(
                (s) => s.healthPermissionDenied,
                'healthPermissionDenied',
                false,
              ),
        ],
        verify: (_) {
          verifyNever(() => mockHealthService.requestPermissions());
          final writes = verify(
            () => storage.write(
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

    group('CheckHealthSyncStatus', () {
      blocTest<AppSettingsBloc, AppSettingsState>(
        'revokes and persists sync when native permissions were revoked '
        'outside the app',
        setUp: () {
          when(
            () => mockHealthService.hasPermissions(),
          ).thenAnswer((_) async => false);
        },
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        seed: () => const AppSettingsState(isHealthSyncEnabled: true),
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                false,
              )
              .having(
                (s) => s.isHealthApiAvailable,
                'isHealthApiAvailable',
                true,
              ),
        ],
        verify: (_) {
          verify(() => mockHealthService.hasPermissions()).called(1);
          final writes = verify(
            () => storage.write(
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

      blocTest<AppSettingsBloc, AppSettingsState>(
        'keeps sync enabled while native permissions remain granted',
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        seed: () => const AppSettingsState(
          isHealthSyncEnabled: true,
          isHealthApiAvailable: false,
        ),
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [
          isA<AppSettingsState>()
              .having(
                (s) => s.isHealthSyncEnabled,
                'isHealthSyncEnabled',
                true,
              )
              .having(
                (s) => s.isHealthApiAvailable,
                'isHealthApiAvailable',
                true,
              ),
        ],
        verify: (_) {
          verify(() => mockHealthService.isHealthApiAvailable()).called(1);
          verify(() => mockHealthService.hasPermissions()).called(1);
        },
      );

      blocTest<AppSettingsBloc, AppSettingsState>(
        'updates availability when the health API is unavailable',
        setUp: () {
          when(
            () => mockHealthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
        },
        build: () => AppSettingsBloc(
          notificationService: mockNotificationService,
          healthService: mockHealthService,
        ),
        act: (bloc) => bloc.add(const CheckHealthSyncStatus()),
        expect: () => [
          isA<AppSettingsState>().having(
            (s) => s.isHealthApiAvailable,
            'isHealthApiAvailable',
            false,
          ),
        ],
        verify: (_) {
          verify(() => mockHealthService.isHealthApiAvailable()).called(1);
          verifyNever(() => mockHealthService.hasPermissions());
        },
      );
    });

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits locked state on SetLocked(true)',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const SetLocked(true)),
      expect: () => [
        isA<AppSettingsState>().having((s) => s.isLocked, 'isLocked', true),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'clears locked state on SetLocked(false)',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(isLocked: true),
      act: (bloc) => bloc.add(const SetLocked(false)),
      expect: () => [
        isA<AppSettingsState>().having((s) => s.isLocked, 'isLocked', false),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'emits updated state on CompleteOnboarding',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      act: (bloc) => bloc.add(const CompleteOnboarding()),
      expect: () => [
        isA<AppSettingsState>().having(
          (s) => s.isOnboardingCompleted,
          'isOnboardingCompleted',
          true,
        ),
      ],
    );

    blocTest<AppSettingsBloc, AppSettingsState>(
      'preserves other fields when updating theme',
      build: () =>
          AppSettingsBloc(notificationService: mockNotificationService),
      seed: () => const AppSettingsState(
        measurementUnit: MeasurementUnit.imperial,
        height: 185.0,
        notificationsEnabled: false,
        notificationTime: TimeOfDay(hour: 10, minute: 0),
        isOnboardingCompleted: true,
      ),
      act: (bloc) => bloc.add(const UpdateTheme(AppThemeMode.light)),
      expect: () => [
        isA<AppSettingsState>()
            .having((s) => s.themeMode, 'themeMode', AppThemeMode.light)
            .having(
              (s) => s.measurementUnit,
              'measurementUnit',
              MeasurementUnit.imperial,
            )
            .having((s) => s.height, 'height', 185.0)
            .having(
              (s) => s.notificationsEnabled,
              'notificationsEnabled',
              false,
            )
            .having(
              (s) => s.notificationTime,
              'notificationTime',
              const TimeOfDay(hour: 10, minute: 0),
            )
            .having(
              (s) => s.isOnboardingCompleted,
              'isOnboardingCompleted',
              true,
            ),
      ],
    );

    test('fromJson parses all fields correctly', () {
      final json = {
        'themeMode': 'dark',
        'measurementUnit': 'imperial',
        'height': 175.5,
        'notificationsEnabled': false,
        'notificationTime': {'hour': 14, 'minute': 30},
        'isOnboardingCompleted': true,
        'isHealthSyncEnabled': true,
      };

      final state = AppSettingsState.fromJson(json);

      expect(state.themeMode, AppThemeMode.dark);
      expect(state.measurementUnit, MeasurementUnit.imperial);
      expect(state.height, 175.5);
      expect(state.notificationsEnabled, false);
      expect(state.notificationTime, const TimeOfDay(hour: 14, minute: 30));
      expect(state.isOnboardingCompleted, true);
      expect(state.isHealthSyncEnabled, true);
      expect(state.notificationPermissionDenied, false);
    });

    test(
      'fromJson enforces isLocked true when isBiometricLockEnabled is true',
      () {
        final json = {'isBiometricLockEnabled': true, 'isLocked': false};

        final state = AppSettingsState.fromJson(json);

        expect(state.isBiometricLockEnabled, isTrue);
        expect(state.isLocked, isTrue);
      },
    );

    test('fromJson uses defaults for invalid enum values', () {
      final json = {
        'themeMode': 'invalid',
        'measurementUnit': 'invalid',
        'height': 175.5,
        'notificationsEnabled': false,
        'notificationTime': {'hour': 14, 'minute': 30},
      };

      final state = AppSettingsState.fromJson(json);

      expect(state.themeMode, AppThemeMode.system);
      expect(state.measurementUnit, MeasurementUnit.metric);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final state = AppSettingsState.fromJson(json);

      expect(state.themeMode, AppThemeMode.system);
      expect(state.measurementUnit, MeasurementUnit.metric);
      expect(state.height, isNull);
      expect(state.notificationsEnabled, false);
      expect(state.notificationTime, const TimeOfDay(hour: 8, minute: 0));
      expect(state.isOnboardingCompleted, false);
    });

    test('fromJson handles corrupted notificationTime gracefully', () {
      final json = {
        'themeMode': 'dark',
        'measurementUnit': 'imperial',
        'height': 175.5,
        'notificationsEnabled': false,
        'notificationTime': 'corrupted',
      };

      final state = AppSettingsState.fromJson(json);

      expect(state.notificationTime, const TimeOfDay(hour: 8, minute: 0));
    });

    test(
      'fromJson handles notificationTime with non-int hour/minute gracefully',
      () {
        final json = {
          'themeMode': 'dark',
          'measurementUnit': 'imperial',
          'height': 175.5,
          'notificationsEnabled': false,
          'notificationTime': {'hour': 'not_a_number', 'minute': null},
        };

        final state = AppSettingsState.fromJson(json);

        expect(state.notificationTime, const TimeOfDay(hour: 8, minute: 0));
      },
    );

    test('toJson serializes all fields correctly', () {
      final state = const AppSettingsState(
        themeMode: AppThemeMode.dark,
        measurementUnit: MeasurementUnit.imperial,
        height: 175.5,
        notificationsEnabled: false,
        notificationTime: TimeOfDay(hour: 14, minute: 30),
        isOnboardingCompleted: true,
      );

      final json = state.toJson();

      expect(json['themeMode'], 'dark');
      expect(json['measurementUnit'], 'imperial');
      expect(json['heightCm'], 175.5);
      expect(json['notificationsEnabled'], false);
      expect(json['notificationTime']['hour'], 14);
      expect(json['notificationTime']['minute'], 30);
      expect(json['isOnboardingCompleted'], true);
      expect(json['isHealthSyncEnabled'], false);
    });

    test('toJson serializes defaults correctly', () {
      final state = const AppSettingsState();

      final json = state.toJson();

      expect(json['themeMode'], 'system');
      expect(json['measurementUnit'], 'metric');
      expect(json['heightCm'], isNull);
      expect(json['notificationsEnabled'], false);
      expect(json['notificationTime']['hour'], 8);
      expect(json['notificationTime']['minute'], 0);
      expect(json['isOnboardingCompleted'], false);
      expect(json['isHealthSyncEnabled'], false);
    });

    test('copyWith creates updated copy', () {
      const original = AppSettingsState(
        themeMode: AppThemeMode.light,
        measurementUnit: MeasurementUnit.metric,
        height: 165.0,
        notificationsEnabled: true,
        notificationTime: TimeOfDay(hour: 7, minute: 0),
        isOnboardingCompleted: false,
      );

      final updated = original.copyWith(
        themeMode: AppThemeMode.dark,
        height: 180.0,
        isOnboardingCompleted: true,
        isHealthSyncEnabled: true,
        isHealthApiAvailable: false,
        healthPermissionDenied: true,
      );

      expect(updated.themeMode, AppThemeMode.dark);
      expect(updated.measurementUnit, MeasurementUnit.metric);
      expect(updated.height, 180.0);
      expect(updated.notificationsEnabled, true);
      expect(updated.notificationTime, const TimeOfDay(hour: 7, minute: 0));
      expect(updated.isOnboardingCompleted, true);
      expect(updated.isHealthSyncEnabled, true);
      expect(updated.isHealthApiAvailable, false);
      expect(updated.healthPermissionDenied, true);
    });
  });
}
