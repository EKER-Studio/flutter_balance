import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';

class MockHealthService extends Mock implements HealthService {}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const ToggleHealthSync(false));
    registerFallbackValue(DateTime.now());
  });

  late MockHealthService mockHealthService;
  late MockWeightRepository mockRepository;
  late MockAppSettingsBloc mockSettingsBloc;
  late HealthSyncCoordinator coordinator;

  setUp(() {
    mockHealthService = MockHealthService();
    mockRepository = MockWeightRepository();
    mockSettingsBloc = MockAppSettingsBloc();
    coordinator = HealthSyncCoordinator(
      healthService: mockHealthService,
      repository: mockRepository,
    );

    when(
      () => mockSettingsBloc.state,
    ).thenReturn(const AppSettingsState(isHealthSyncEnabled: true));
  });

  group('HealthSyncCoordinator', () {
    test(
      'fetches and syncs remote entries successfully',
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

        await coordinator.sync(settingsBloc: mockSettingsBloc);

        verify(() => mockRepository.syncRemoteEntries([remoteEntry])).called(1);
        verify(
          () => mockSettingsBloc.add(
            any(that: isA<UpdateLastHealthSyncTimestamp>()),
          ),
        ).called(1);
      },
    );

    test(
      'mirrorWrite invokes healthService.writeWeight',
      () async {
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
      },
    );

    test(
      'mirrorDelete invokes healthService.deleteWeight',
      () async {
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
      },
    );
  });
}
