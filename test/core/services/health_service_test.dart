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

void main() {
  late MockHealthPlugin health;
  late NativeHealthService service;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(HealthDataType.WEIGHT);
    registerFallbackValue(HealthDataUnit.KILOGRAM);
    registerFallbackValue(RecordingMethod.manual);
    registerFallbackValue(const [HealthDataType.WEIGHT]);
  });

  setUp(() {
    health = MockHealthPlugin();
    service = NativeHealthService(health: health);
    PermissionHandlerPlatform.instance = FakePermissionHandler(true);
  });

  tearDown(() {
    PermissionHandlerPlatform.instance = FakePermissionHandler(true);
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
    test('returns true on iOS-like hosts without consulting the plugin', () async {
      final available = await service.isHealthApiAvailable();

      expect(available, isTrue);
      verifyNever(
        () => health.isHealthConnectAvailable(),
      );
    });
  });

  group('NativeHealthService.hasPermissions', () {
    test('returns true when the platform reports granted access', () async {
      when(
        () => health.hasPermissions(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.hasPermissions(), isTrue);
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
    test('returns true when authorization is granted', () async {
      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.requestPermissions(), isTrue);
      verify(
        () => health.requestAuthorization(
          [HealthDataType.WEIGHT],
          permissions: [HealthDataAccess.READ, HealthDataAccess.WRITE],
        ),
      ).called(1);
    });

    test('returns false when authorization is declined', () async {
      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.requestPermissions(), isFalse);
    });

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

      final entries = await service.fetchWeightHistory(
        start: date,
        end: date,
      );

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
  });

  group('NativeHealthService.writeWeight', () {
    test('delegates with the manual recording method and returns the result',
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
    });

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
  });

  group('NativeHealthService.deleteWeight', () {
    test('deletes the point matching weight and timestamp within tolerance',
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
        () => health.deleteByUUID(
          uuid: 'match',
          type: HealthDataType.WEIGHT,
        ),
      ).called(1);
    });

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
        await service.deleteWeight(
          weightKg: 72.5,
          timestamp: timestamp,
        ),
        isFalse,
      );
    });
  });
}
