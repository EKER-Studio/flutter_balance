import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';

class MockHealthService extends Mock implements HealthService {}

class MockWeightRepository extends Mock implements WeightRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  late MockHealthService mockHealthService;
  late MockWeightRepository mockRepository;
  late HealthSyncCoordinator coordinator;

  setUp(() {
    mockHealthService = MockHealthService();
    mockRepository = MockWeightRepository();
    coordinator = HealthSyncCoordinator(
      healthService: mockHealthService,
      repository: mockRepository,
    );
  });

  group('HealthSyncCoordinator', () {
    test(
      'fetches and syncs remote entries returning HealthSyncResult',
      () async {
        final remoteEntry = WeightEntry(
          id: 1,
          weightKg: 75.0,
          dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        );
        when(
          () => mockHealthService.fetchWeightHistory(
            start: any(named: 'start'),
            end: any(named: 'end'),
          ),
        ).thenAnswer((_) async => [remoteEntry]);
        when(
          () => mockRepository.syncRemoteEntries([remoteEntry]),
        ).thenAnswer((_) async => 1);
        when(
          () => mockRepository.getAllEntries(),
        ).thenAnswer((_) async => [remoteEntry]);

        final result = await coordinator.sync();

        expect(result, isNotNull);
        expect(result!.remoteCount, 1);
        expect(result.pushedLocalCount, 0);
        verify(() => mockRepository.syncRemoteEntries([remoteEntry])).called(1);
      },
    );

    test('pushes local entries missing from remote health service', () async {
      final now = DateTime.now();
      final localOnlyEntry = WeightEntry(
        id: 2,
        weightKg: 82.0,
        dateTime: now.subtract(const Duration(days: 2)),
      );
      when(
        () => mockHealthService.fetchWeightHistory(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockRepository.getAllEntries(),
      ).thenAnswer((_) async => [localOnlyEntry]);
      when(
        () => mockHealthService.writeWeight(
          weightKg: any(named: 'weightKg'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer((_) async => true);

      final result = await coordinator.sync(
        lastSyncTime: now.subtract(const Duration(days: 5)),
      );

      expect(result, isNotNull);
      expect(result!.remoteCount, 0);
      expect(result.pushedLocalCount, 1);
    });

    test('returns null when healthService throws during sync', () async {
      when(
        () => mockHealthService.fetchWeightHistory(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenThrow(Exception('Health service unavailable'));

      final result = await coordinator.sync();

      expect(result, isNull);
    });

    test('mirrorWrite invokes healthService.writeWeight', () async {
      when(
        () => mockHealthService.writeWeight(
          weightKg: any(named: 'weightKg'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer((_) async => true);

      final entry = WeightEntry(
        weightKg: 72.5,
        dateTime: DateTime(2026, 8, 24, 10, 0),
      );

      await coordinator.mirrorWrite(entry);

      verify(
        () => mockHealthService.writeWeight(
          weightKg: 72.5,
          timestamp: DateTime(2026, 8, 24, 10, 0),
        ),
      ).called(1);
    });

    test(
      'mirrorWrite catches error when healthService.writeWeight throws',
      () async {
        when(
          () => mockHealthService.writeWeight(
            weightKg: any(named: 'weightKg'),
            timestamp: any(named: 'timestamp'),
          ),
        ).thenThrow(Exception('Write failed'));

        final entry = WeightEntry(
          weightKg: 72.5,
          dateTime: DateTime(2026, 8, 24, 10, 0),
        );

        await expectLater(coordinator.mirrorWrite(entry), completes);
      },
    );

    test('mirrorDelete invokes healthService.deleteWeight', () async {
      when(
        () => mockHealthService.deleteWeight(
          weightKg: any(named: 'weightKg'),
          timestamp: any(named: 'timestamp'),
        ),
      ).thenAnswer((_) async => true);

      final timestamp = DateTime(2026, 8, 24, 10, 0);
      await coordinator.mirrorDelete(72.5, timestamp);

      verify(
        () => mockHealthService.deleteWeight(
          weightKg: 72.5,
          timestamp: timestamp,
        ),
      ).called(1);
    });

    test(
      'mirrorDelete catches error when healthService.deleteWeight throws',
      () async {
        when(
          () => mockHealthService.deleteWeight(
            weightKg: any(named: 'weightKg'),
            timestamp: any(named: 'timestamp'),
          ),
        ).thenThrow(Exception('Delete failed'));

        final timestamp = DateTime(2026, 8, 24, 10, 0);
        await expectLater(coordinator.mirrorDelete(72.5, timestamp), completes);
      },
    );
  });
}
