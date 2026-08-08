import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:balance/core/services/health_service.dart';

/// Mock for the `health` plugin facade.
class MockHealthPlugin extends Mock implements Health {}

/// Permission platform stub whose [openAppSettings] always returns [result].
class FakePermissionHandler extends PermissionHandlerPlatform {
  FakePermissionHandler(this.result);

  final bool result;

  @override
  Future<bool> openAppSettings() async => result;
}

/// Permission platform stub whose [openAppSettings] always throws, simulating
/// a host without a native method channel implementation.
class _ThrowingPermissionHandler extends PermissionHandlerPlatform {
  @override
  Future<bool> openAppSettings() async =>
      throw Exception('Native settings channel unavailable');
}

/// Permission platform stub whose [openAppSettings] delays beyond the service
/// timeout threshold, simulating an unresponsive native channel.
class _SlowPermissionHandler extends PermissionHandlerPlatform {
  @override
  Future<bool> openAppSettings() async =>
      Future.delayed(const Duration(seconds: 6), () => true);
}

/// Permission platform stub that tracks invocation count.
class _TrackingPermissionHandler extends PermissionHandlerPlatform {
  static int callCount = 0;

  @override
  Future<bool> openAppSettings() async {
    callCount++;
    return true;
  }
}

// Add mock for PlatformDetector
class MockPlatformDetector extends Mock implements PlatformDetector {}

void main() {
  late MockHealthPlugin health;
  late NativeHealthService service;
  late MockPlatformDetector platformDetector;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(HealthDataType.WEIGHT);
    registerFallbackValue(HealthDataUnit.KILOGRAM);
    registerFallbackValue(RecordingMethod.manual);
    registerFallbackValue(const [HealthDataType.WEIGHT]);
  });

  setUp(() {
    health = MockHealthPlugin();
    platformDetector = MockPlatformDetector();
    service = NativeHealthService(
      health: health,
      platformDetector: platformDetector,
    );
    PermissionHandlerPlatform.instance = FakePermissionHandler(true);
    _TrackingPermissionHandler.callCount = 0;

    // Configuration must never throw in tests.
    when(() => health.configure()).thenAnswer((_) async {});

    // Default to iOS for tests that don't specify otherwise
    when(() => platformDetector.isAndroid).thenReturn(false);
    when(() => platformDetector.isIOS).thenReturn(true);
  });

  tearDown(() {
    PermissionHandlerPlatform.instance = FakePermissionHandler(true);
    _TrackingPermissionHandler.callCount = 0;
  });

  HealthDataPoint point({
    required String uuid,
    required num value,
    required DateTime dateFrom,
  }) {
    return HealthDataPoint(
      uuid: uuid,
      value: NumericHealthValue(numericValue: value),
      type: HealthDataType.WEIGHT,
      unit: HealthDataUnit.KILOGRAM,
      dateFrom: dateFrom,
      dateTo: dateFrom,
      sourcePlatform: HealthPlatformType.appleHealth,
      sourceDeviceId: 'device-1',
      sourceId: 'source-1',
      sourceName: 'Balance',
    );
  }

  group('NativeHealthService.isHealthApiAvailable', () {
    test(
      'returns true on iOS-like hosts without consulting the plugin',
      () async {
        // Simulate iOS platform
        when(() => platformDetector.isAndroid).thenReturn(false);
        when(() => platformDetector.isIOS).thenReturn(true);

        final available = await service.isHealthApiAvailable();

        expect(available, isTrue);
        verifyNever(() => health.isHealthConnectAvailable());
      },
    );
    test('returns true on Android when Health Connect is available', () async {
      // Simulate Android platform with Health Connect available
      when(() => platformDetector.isAndroid).thenReturn(true);
      when(() => platformDetector.isIOS).thenReturn(false);
      when(
        () => health.getHealthConnectSdkStatus(),
      ).thenAnswer((_) async => HealthConnectSdkStatus.sdkAvailable);
      final available = await service.isHealthApiAvailable();

      expect(available, isTrue);
      verify(() => platformDetector.isAndroid).called(1);
      verify(() => health.getHealthConnectSdkStatus()).called(1);
    });

    test(
      'returns false on Android when Health Connect is unavailable',
      () async {
        // Simulate Android platform with Health Connect unavailable
        when(() => platformDetector.isAndroid).thenReturn(true);
        when(() => platformDetector.isIOS).thenReturn(false);
        when(
          () => health.getHealthConnectSdkStatus(),
        ).thenAnswer((_) async => HealthConnectSdkStatus.sdkUnavailable);

        final available = await service.isHealthApiAvailable();

        expect(available, isFalse);
        verify(() => platformDetector.isAndroid).called(1);
        verify(() => health.getHealthConnectSdkStatus()).called(1);
      },
    );

    test('returns false on Android when Health Connect check throws', () async {
      // Simulate Android platform with Health Connect check throwing
      when(() => platformDetector.isAndroid).thenReturn(true);
      when(() => platformDetector.isIOS).thenReturn(false);
      when(
        () => health.getHealthConnectSdkStatus(),
      ).thenThrow(Exception('Health Connect unavailable'));

      final available = await service.isHealthApiAvailable();

      expect(available, isFalse);
      verify(() => platformDetector.isAndroid).called(1);
      verify(() => health.getHealthConnectSdkStatus()).called(1);
    });
  });

  group('NativeHealthService.hasPermissions', () {
    test(
      'returns true when WEIGHT read/write permissions are granted on iOS',
      () async {
        when(() => platformDetector.isIOS).thenReturn(true);

        when(
          () => health.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => true);

        expect(await service.hasPermissions(), isTrue);
      },
    );

    test(
      'returns true when WEIGHT read/write permissions are granted on Android',
      () async {
        when(() => platformDetector.isIOS).thenReturn(false);
        when(() => platformDetector.isAndroid).thenReturn(true);

        when(
          () => health.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => true);

        expect(await service.hasPermissions(), isTrue);
      },
    );

    test('returns false when user denies permissions on iOS', () async {
      when(() => platformDetector.isIOS).thenReturn(true);

      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.hasPermissions(), isFalse);
    });

    test('returns false when user denies permissions on Android', () async {
      when(() => platformDetector.isIOS).thenReturn(false);
      when(() => platformDetector.isAndroid).thenReturn(true);

      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.hasPermissions(), isFalse);
    });

    test('treats a null grant as denied', () async {
      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => null);

      expect(await service.hasPermissions(), isFalse);
    });

    test('catches plugin errors and reports denial', () async {
      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenThrow(Exception('Native permission check failed'));

      expect(await service.hasPermissions(), isFalse);
    });
  });

  group('NativeHealthService.requestPermissions', () {
    test('returns true on Android when authorization is granted', () async {
      when(() => platformDetector.isAndroid).thenReturn(true);
      when(() => platformDetector.isIOS).thenReturn(false);

      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);

      final granted = await service.requestPermissions();

      expect(granted, isTrue);
      verifyNever(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      );
    });

    test('returns true on iOS when authorization prompt is shown and '
        'hasPermissions returns true', () async {
      when(() => platformDetector.isAndroid).thenReturn(false);
      when(() => platformDetector.isIOS).thenReturn(true);

      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);

      final granted = await service.requestPermissions();

      expect(granted, isTrue);
      verify(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).called(1);
    });

    test(
      'returns false on iOS when authorization is declined by the user',
      () async {
        when(() => platformDetector.isIOS).thenReturn(true);
        when(() => platformDetector.isAndroid).thenReturn(false);

        when(
          () => health.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => false);

        expect(await service.requestPermissions(), isFalse);
      },
    );

    test(
      'returns false on Android when authorization is declined by the user',
      () async {
        when(() => platformDetector.isIOS).thenReturn(false);
        when(() => platformDetector.isAndroid).thenReturn(true);

        when(
          () => health.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => false);

        expect(await service.requestPermissions(), isFalse);
      },
    );

    test('catches plugin errors and reports denial', () async {
      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenThrow(Exception('Native authorization failed'));

      expect(await service.requestPermissions(), isFalse);
    });
  });

  group('NativeHealthService.openSystemSettings', () {
    test('returns the platform result when settings can be opened', () async {
      expect(await service.openSystemSettings(), isTrue);
    });

    test('returns false when the platform cannot open settings', () async {
      PermissionHandlerPlatform.instance = FakePermissionHandler(false);

      expect(await service.openSystemSettings(), isFalse);
    });

    test('returns false when the platform channel is unavailable', () async {
      PermissionHandlerPlatform.instance = _ThrowingPermissionHandler();

      expect(await service.openSystemSettings(), isFalse);
    });

    test('triggers the OS settings call via permission_handler', () async {
      PermissionHandlerPlatform.instance = _TrackingPermissionHandler();

      await service.openSystemSettings();

      expect(_TrackingPermissionHandler.callCount, 1);
    });
  });

  group('NativeHealthService.installHealthConnect', () {
    test('is a no-op on non-Android platforms', () async {
      when(() => platformDetector.isAndroid).thenReturn(false);
      when(() => platformDetector.isIOS).thenReturn(true);

      await expectLater(service.installHealthConnect(), completes);
    });

    test(
      'completes without throwing when the launcher channel is missing',
      () async {
        when(() => platformDetector.isAndroid).thenReturn(true);
        when(() => platformDetector.isIOS).thenReturn(false);

        await expectLater(service.installHealthConnect(), completes);
      },
    );
  });

  group('NativeHealthService timeout behavior', () {
    test(
      'hasPermissions falls back to false when plugin exceeds timeout',
      () async {
        when(
          () => health.hasPermissions(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer((_) async => Future.delayed(const Duration(seconds: 6)));

        expect(await service.hasPermissions(), isFalse);
      },
    );

    test(
      'requestPermissions falls back to false when plugin exceeds timeout',
      () async {
        when(
          () => health.requestAuthorization(
            any(),
            permissions: any(named: 'permissions'),
          ),
        ).thenAnswer(
          (_) async => Future.delayed(const Duration(seconds: 6), () => true),
        );

        expect(await service.requestPermissions(), isFalse);
      },
    );

    test(
      'openSystemSettings falls back to false when plugin exceeds timeout',
      () async {
        PermissionHandlerPlatform.instance = _SlowPermissionHandler();

        expect(await service.openSystemSettings(), isFalse);
      },
    );
  });

  group('NativeHealthService.fetchWeightHistory', () {
    test('maps numeric points to entries sorted newest first', () async {
      final older = DateTime(2026, 1, 1, 8, 30);
      final newer = DateTime(2026, 1, 2, 9, 45);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'older', value: 70, dateFrom: older),
          point(uuid: 'newer', value: 75.5, dateFrom: newer),
        ],
      );

      final entries = await service.fetchWeightHistory(
        start: older,
        end: newer,
      );

      expect(entries, hasLength(2));
      expect(entries.first.weightKg, 75.5);
      expect(entries.first.dateTime, newer);
      expect(entries.last.weightKg, 70);
      expect(entries.last.dateTime, older);
    });

    test('skips points whose value is not numeric', () async {
      final date = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          HealthDataPoint(
            uuid: 'non-numeric',
            value: HealthValue(),
            type: HealthDataType.WEIGHT,
            unit: HealthDataUnit.KILOGRAM,
            dateFrom: date,
            dateTo: date,
            sourcePlatform: HealthPlatformType.appleHealth,
            sourceDeviceId: 'device-1',
            sourceId: 'source-1',
            sourceName: 'Balance',
          ),
        ],
      );

      final entries = await service.fetchWeightHistory(start: date, end: date);

      expect(entries, isEmpty);
    });

    test('returns an empty list when the plugin errors out', () async {
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenThrow(Exception('Native query failed'));

      final entries = await service.fetchWeightHistory(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 2),
      );

      expect(entries, isEmpty);
    });

    test('filters out entries below minimum weight threshold', () async {
      final date = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'corrupt-low', value: 19.9, dateFrom: date),
          point(uuid: 'valid', value: 75.5, dateFrom: date),
        ],
      );

      final entries = await service.fetchWeightHistory(start: date, end: date);

      expect(entries, hasLength(1));
      expect(entries.first.weightKg, 75.5);
    });

    test('filters out entries above maximum weight threshold', () async {
      final date = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'corrupt-high', value: 300.1, dateFrom: date),
          point(uuid: 'valid', value: 80.0, dateFrom: date),
        ],
      );

      final entries = await service.fetchWeightHistory(start: date, end: date);

      expect(entries, hasLength(1));
      expect(entries.first.weightKg, 80.0);
    });

    test('filters out all entries when none are within bounds', () async {
      final date = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'corrupt-low', value: 5.0, dateFrom: date),
          point(uuid: 'corrupt-high', value: 500.0, dateFrom: date),
        ],
      );

      final entries = await service.fetchWeightHistory(start: date, end: date);

      expect(entries, isEmpty);
    });

    test('keeps entries exactly at boundary values', () async {
      final date = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'lower-bound', value: 20.0, dateFrom: date),
          point(uuid: 'upper-bound', value: 300.0, dateFrom: date),
        ],
      );

      final entries = await service.fetchWeightHistory(start: date, end: date);

      expect(entries, hasLength(2));
    });
  });

  group('NativeHealthService.writeWeight', () {
    test(
      'delegates with the manual recording method and returns the result',
      () async {
        final timestamp = DateTime(2026, 1, 1, 8, 30);
        when(
          () => health.writeHealthData(
            value: any(named: 'value'),
            unit: any(named: 'unit'),
            type: any(named: 'type'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            recordingMethod: any(named: 'recordingMethod'),
          ),
        ).thenAnswer((_) async => true);

        final written = await service.writeWeight(
          weightKg: 72.5,
          timestamp: timestamp,
        );

        expect(written, isTrue);
        verify(
          () => health.writeHealthData(
            value: 72.5,
            unit: HealthDataUnit.KILOGRAM,
            type: HealthDataType.WEIGHT,
            startTime: timestamp,
            endTime: timestamp,
            recordingMethod: RecordingMethod.manual,
          ),
        ).called(1);
      },
    );

    test('catches plugin errors and reports failure', () async {
      when(
        () => health.writeHealthData(
          value: any(named: 'value'),
          unit: any(named: 'unit'),
          type: any(named: 'type'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          recordingMethod: any(named: 'recordingMethod'),
        ),
      ).thenThrow(Exception('Native write failed'));

      expect(
        await service.writeWeight(
          weightKg: 72.5,
          timestamp: DateTime(2026, 1, 1, 8, 30),
        ),
        isFalse,
      );
    });

    test('passes exact weight value and timestamp to the plugin', () async {
      final weight = 93.7;
      final timestamp = DateTime(2026, 6, 15, 14, 22, 33);
      when(
        () => health.writeHealthData(
          value: any(named: 'value'),
          unit: any(named: 'unit'),
          type: any(named: 'type'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          recordingMethod: any(named: 'recordingMethod'),
        ),
      ).thenAnswer((_) async => true);

      await service.writeWeight(weightKg: weight, timestamp: timestamp);

      verify(
        () => health.writeHealthData(
          value: weight,
          unit: HealthDataUnit.KILOGRAM,
          type: HealthDataType.WEIGHT,
          startTime: timestamp,
          endTime: timestamp,
          recordingMethod: RecordingMethod.manual,
        ),
      ).called(1);
    });
  });

  group('NativeHealthService.deleteWeight', () {
    test(
      'deletes the point matching weight and timestamp within tolerance',
      () async {
        final timestamp = DateTime(2026, 1, 1, 8, 30);
        when(
          () => health.getHealthDataFromTypes(
            types: any(named: 'types'),
            preferredUnits: any(named: 'preferredUnits'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).thenAnswer(
          (_) async => [
            point(uuid: 'other', value: 80, dateFrom: timestamp),
            point(uuid: 'match', value: 72.5, dateFrom: timestamp),
          ],
        );
        when(
          () => health.deleteByUUID(
            uuid: any(named: 'uuid'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => true);

        final deleted = await service.deleteWeight(
          weightKg: 72.5,
          timestamp: timestamp,
        );

        expect(deleted, isTrue);
        verify(
          () => health.deleteByUUID(uuid: 'match', type: HealthDataType.WEIGHT),
        ).called(1);
      },
    );

    test('does not delete anything when no point matches', () async {
      final timestamp = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [point(uuid: 'other', value: 80, dateFrom: timestamp)],
      );

      final deleted = await service.deleteWeight(
        weightKg: 72.5,
        timestamp: timestamp,
      );

      expect(deleted, isFalse);
      verifyNever(
        () => health.deleteByUUID(
          uuid: any(named: 'uuid'),
          type: any(named: 'type'),
        ),
      );
    });

    test('catches plugin errors and reports failure', () async {
      final timestamp = DateTime(2026, 1, 1, 8, 30);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenThrow(Exception('Native query failed'));

      expect(
        await service.deleteWeight(weightKg: 72.5, timestamp: timestamp),
        isFalse,
      );
    });

    test('passes exact weight and timestamp for lookup and deletion', () async {
      final weight = 88.3;
      final timestamp = DateTime(2026, 3, 20, 11, 5, 10);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer(
        (_) async => [
          point(uuid: 'target', value: weight, dateFrom: timestamp),
        ],
      );
      when(
        () => health.deleteByUUID(
          uuid: any(named: 'uuid'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => true);

      await service.deleteWeight(weightKg: weight, timestamp: timestamp);

      verify(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          preferredUnits: any(named: 'preferredUnits'),
          startTime: timestamp.subtract(const Duration(minutes: 1)),
          endTime: timestamp.add(const Duration(minutes: 1)),
        ),
      ).called(1);
      verify(
        () => health.deleteByUUID(uuid: 'target', type: HealthDataType.WEIGHT),
      ).called(1);
    });
  });
}
