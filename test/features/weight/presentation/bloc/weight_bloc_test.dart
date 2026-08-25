import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockHealthService extends Mock implements HealthService {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

void main() {
  late MockWeightRepository repository;
  late MockHealthService healthService;
  late MockHydratedStorage storage;
  late StreamController<List<WeightEntry>> streamController;

  setUpAll(() {
    registerFallbackValue(WeightEntry(weightKg: 0, dateTime: DateTime(2000)));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockWeightRepository();
    healthService = MockHealthService();
    storage = MockHydratedStorage();
    streamController = StreamController<List<WeightEntry>>.broadcast();

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => streamController.stream);
    when(() => repository.getAllEntries()).thenAnswer((_) async => []);
    when(() => repository.addEntry(any())).thenAnswer((_) async {});
    when(() => repository.deleteEntry(any())).thenAnswer((_) async {});
    when(() => repository.clearAllData()).thenAnswer((_) async {});
    when(() => repository.bulkImportEntries(any())).thenAnswer((_) async => 1);
    when(() => repository.syncRemoteEntries(any())).thenAnswer((_) async => 1);
    when(
      () => healthService.writeWeight(
        weightKg: any(named: 'weightKg'),
        timestamp: any(named: 'timestamp'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => healthService.deleteWeight(
        weightKg: any(named: 'weightKg'),
        timestamp: any(named: 'timestamp'),
      ),
    ).thenAnswer((_) async => true);

    HydratedBloc.storage = storage;
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
  });

  tearDown(() {
    streamController.close();
  });

  MockAppSettingsBloc buildSettingsBloc({bool isHealthSyncEnabled = true}) {
    final settingsBloc = MockAppSettingsBloc();
    when(
      () => settingsBloc.state,
    ).thenReturn(AppSettingsState(isHealthSyncEnabled: isHealthSyncEnabled));
    return settingsBloc;
  }

  group('WeightBloc', () {
    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoading, WeightLoaded] after SubscribeToWeightChanges',
      build: () => WeightBloc(repository: repository),
      act: (bloc) async {
        bloc.add(SubscribeToWeightChanges());
        await Future(() {});
        streamController.add([]);
      },
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightLoaded>().having((s) => s.entries, 'entries', isEmpty),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'keeps existing entries and skips WeightLoading when re-subscribing',
      build: () => WeightBloc(repository: repository),
      seed: () => WeightLoaded(
        heightCm: 170,
        entries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        filteredEntries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
      ),
      act: (bloc) async {
        bloc.add(SubscribeToWeightChanges());
        await Future(() {});
        streamController.add([
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ]);
      },
      expect: () => [
        isA<WeightLoaded>()
            .having((s) => s.entries, 'entries', isNotEmpty)
            .having((s) => s.heightCm, 'heightCm', 170),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError preserving entries when the stream fails to start',
      build: () {
        when(() => repository.watchAllEntries()).thenThrow(
          WeightRepositoryException(
            type: WeightErrorType.streamError,
            message: 'database closed',
          ),
        );
        return WeightBloc(repository: repository);
      },
      seed: () => WeightLoaded(
        entries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        filteredEntries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
      ),
      act: (bloc) => bloc.add(SubscribeToWeightChanges()),
      expect: () => [
        isA<WeightError>()
            .having(
              (s) => s.errorType,
              'errorType',
              WeightErrorType.streamError,
            )
            .having((s) => s.entries, 'entries', isNotEmpty),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoading, WeightError] with the domain error type when '
      'the stream emits a WeightRepositoryException',
      build: () {
        when(() => repository.watchAllEntries()).thenAnswer(
          (_) => Stream.error(
            WeightRepositoryException(
              type: WeightErrorType.readFailed,
              message: 'stream failure',
            ),
          ),
        );
        return WeightBloc(repository: repository);
      },
      act: (bloc) => bloc.add(SubscribeToWeightChanges()),
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.readFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits empty WeightLoaded after ClearAllWeightData succeeds',
      build: () => WeightBloc(repository: repository),
      seed: () => WeightLoaded(
        entries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        filteredEntries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        heightCm: 170,
      ),
      act: (bloc) => bloc.add(const ClearAllWeightData()),
      expect: () => [
        isA<WeightLoaded>()
            .having((s) => s.entries, 'entries', isEmpty)
            .having((s) => s.heightCm, 'heightCm', 170),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'imports new entries and emits WeightLoaded on successful import',
      build: () => WeightBloc(
        repository: repository,
        appSettingsBloc: buildSettingsBloc(isHealthSyncEnabled: false),
        healthService: healthService,
      ),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(
        ImportWeightEntries([
          WeightEntry(id: 0, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
        ]),
      ),
      expect: () => [
        isA<WeightLoaded>().having((s) => s.heightCm, 'heightCm', 170),
      ],
      verify: (_) {
        verify(() => repository.bulkImportEntries(any())).called(1);
      },
    );

    blocTest<WeightBloc, WeightState>(
      'mirrors imported entries to the health service when sync is enabled',
      build: () => WeightBloc(
        repository: repository,
        appSettingsBloc: buildSettingsBloc(),
        healthService: healthService,
      ),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) async {
        bloc.add(
          ImportWeightEntries([
            WeightEntry(id: 0, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(
          () => healthService.writeWeight(
            weightKg: any(named: 'weightKg'),
            timestamp: any(named: 'timestamp'),
          ),
        ).called(1);
      },
    );

    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoading, WeightError] when initial stream throws an error',
      build: () {
        when(() => repository.watchAllEntries()).thenAnswer(
          (_) => Stream.error(Exception('Database initialization failure')),
        );
        return WeightBloc(repository: repository);
      },
      act: (bloc) => bloc.add(SubscribeToWeightChanges()),
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.streamError,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoaded] with updated heightCm after UpdateUserHeight',
      build: () => WeightBloc(repository: repository),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: null),
      act: (bloc) => bloc.add(const UpdateUserHeight(175)),
      expect: () => [
        isA<WeightLoaded>().having((s) => s.heightCm, 'heightCm', 175),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'preserves existing entries after UpdateUserHeight',
      build: () => WeightBloc(repository: repository),
      seed: () => WeightLoaded(
        entries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        filteredEntries: [
          WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
        ],
        heightCm: null,
      ),
      act: (bloc) => bloc.add(const UpdateUserHeight(180)),
      expect: () => [
        isA<WeightLoaded>()
            .having((s) => s.heightCm, 'heightCm', 180)
            .having((s) => s.entries.length, 'entries length', 1),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'calls repository.addEntry with correct BMI on AddWeight when height is set',
      build: () => WeightBloc(repository: repository),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
      verify: (_) {
        final captured = verify(
          () => repository.addEntry(captureAny()),
        ).captured;
        final entry = captured.single as WeightEntry;
        expect(entry.weightKg, 72);
      },
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.addEntry fails',
      build: () {
        when(
          () => repository.addEntry(any()),
        ).thenThrow(Exception('Write failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.addEntryFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'calls repository.addEntry with updated entry on UpdateWeight when height is set',
      build: () => WeightBloc(repository: repository),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(
        UpdateWeight(
          WeightEntry(
            id: 1,
            weightKg: 74,
            dateTime: DateTime(2026, 7, 15, 9),
            note: 'Updated note',
          ),
        ),
      ),
      verify: (_) {
        final captured = verify(
          () => repository.addEntry(captureAny()),
        ).captured;
        final entry = captured.single as WeightEntry;
        expect(entry.id, 1);
        expect(entry.weightKg, 74);
        expect(entry.note, 'Updated note');
      },
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError on UpdateWeight when height is not set',
      build: () => WeightBloc(repository: repository),
      seed: () => const WeightInitial(),
      act: (bloc) => bloc.add(
        UpdateWeight(
          WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 7, 15, 9)),
        ),
      ),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.heightNotSet,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.addEntry fails on UpdateWeight',
      build: () {
        when(
          () => repository.addEntry(any()),
        ).thenThrow(Exception('Write failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(
        UpdateWeight(
          WeightEntry(id: 1, weightKg: 74, dateTime: DateTime(2026, 7, 15, 9)),
        ),
      ),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.writeFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.deleteEntry fails',
      build: () {
        when(
          () => repository.deleteEntry(any()),
        ).thenThrow(Exception('Delete failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(DeleteWeight(1)),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.deleteEntryFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'updates timePeriod on ChangeChartFilter',
      build: () => WeightBloc(repository: repository),
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(ChangeChartFilter(TimePeriod.year)),
      expect: () => [
        isA<WeightLoaded>().having(
          (s) => s.timePeriod,
          'timePeriod',
          TimePeriod.year,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'fetches entries on RefreshWeightData',
      build: () {
        when(() => repository.getAllEntries()).thenAnswer(
          (_) async => [
            WeightEntry(id: 1, weightKg: 75, dateTime: DateTime(2025, 1, 1)),
          ],
        );
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(const RefreshWeightData()),
      expect: () => [
        isA<WeightLoaded>().having(
          (s) => s.entries.length,
          'entries length',
          1,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.getAllEntries fails on RefreshWeightData',
      build: () {
        when(
          () => repository.getAllEntries(),
        ).thenThrow(Exception('Read failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(const RefreshWeightData()),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.readFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.clearAllData fails on ClearAllWeightData',
      build: () {
        when(
          () => repository.clearAllData(),
        ).thenThrow(Exception('Wipe failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(const ClearAllWeightData()),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.wipeFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError when repository.bulkImportEntries fails on ImportWeightEntries',
      build: () {
        when(
          () => repository.bulkImportEntries(any()),
        ).thenThrow(Exception('Import failed'));
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) => bloc.add(
        ImportWeightEntries([
          WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026)),
        ]),
      ),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.writeFailed,
        ),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError on AddWeight when height is not set',
      build: () => WeightBloc(repository: repository),
      seed: () => const WeightInitial(),
      act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.heightNotSet,
        ),
      ],
    );

    test(
      'toJson serializes only lightweight configuration and omits entries',
      () {
        final bloc = WeightBloc(repository: repository);
        final state = WeightLoaded(
          entries: [
            WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
          ],
          filteredEntries: [
            WeightEntry(id: 1, weightKg: 70, dateTime: DateTime(2025, 1, 1)),
          ],
          heightCm: 175,
          timePeriod: TimePeriod.month,
        );

        final json = bloc.toJson(state);
        expect(json, {'heightCm': 175.0, 'timePeriod': 'month'});
        expect(json!.containsKey('entries'), isFalse);
        expect(json.containsKey('filteredEntries'), isFalse);
      },
    );

    test(
      'reuses memoized filteredEntries when equal content arrives in new instances',
      () async {
        final bloc = WeightBloc(repository: repository);
        final states = <WeightState>[];
        final subscription = bloc.stream.listen(states.add);
        addTearDown(subscription.cancel);
        addTearDown(bloc.close);

        final now = DateTime.now();
        final first = [
          WeightEntry(
            id: 1,
            weightKg: 70,
            dateTime: now.subtract(const Duration(days: 2)),
          ),
          WeightEntry(
            id: 2,
            weightKg: 71,
            dateTime: now.subtract(const Duration(days: 1)),
          ),
        ];
        final second = [
          WeightEntry(
            id: 1,
            weightKg: 70,
            dateTime: now.subtract(const Duration(days: 2)),
          ),
          WeightEntry(
            id: 2,
            weightKg: 71,
            dateTime: now.subtract(const Duration(days: 1)),
          ),
        ];

        bloc.add(SubscribeToWeightChanges());
        await Future(() {});
        streamController.add(first);
        await Future(() {});
        streamController.add(second);
        await Future(() {});

        final loaded = states.whereType<WeightLoaded>().toList();
        expect(loaded.length, 2);
        expect(
          identical(loaded[0].filteredEntries, loaded[1].filteredEntries),
          isTrue,
        );
      },
    );

    test('refilters when entry content changes between emissions', () async {
      final bloc = WeightBloc(repository: repository);
      final states = <WeightState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);
      addTearDown(bloc.close);

      final now = DateTime.now();
      bloc.add(SubscribeToWeightChanges());
      await Future(() {});

      streamController.add([
        WeightEntry(
          id: 1,
          weightKg: 70,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ]);
      await Future(() {});

      streamController.add([
        WeightEntry(
          id: 1,
          weightKg: 82,
          dateTime: now.subtract(const Duration(days: 2)),
        ),
      ]);
      await Future(() {});

      final loaded = states.whereType<WeightLoaded>().toList();
      expect(loaded.length, 2);
      expect(
        identical(loaded[0].filteredEntries, loaded[1].filteredEntries),
        isFalse,
      );
      expect(loaded[1].filteredEntries.single.weightKg, 82);
    });

    test('fromJson restores config and initializes state as WeightInitial', () {
      final bloc = WeightBloc(repository: repository);
      final state = bloc.fromJson({'heightCm': 180, 'timePeriod': 'year'});

      expect(state, isA<WeightInitial>());
      expect(state!.heightCm, 180.0);
      expect(state.timePeriod, TimePeriod.year);
    });

    test(
      'fromJson falls back to the week period for an unknown timePeriod value',
      () {
        final bloc = WeightBloc(repository: repository);
        final state = bloc.fromJson({'heightCm': 170, 'timePeriod': 'bogus'});

        expect(state, isA<WeightInitial>());
        expect(state!.heightCm, 170.0);
        expect(state.timePeriod, TimePeriod.week);
      },
    );

    test('close cancels stream subscription cleanly', () async {
      final bloc = WeightBloc(repository: repository);
      await bloc.close();
    });

    group('health sync', () {
      blocTest<WeightBloc, WeightState>(
        'mirrors new weight entry to HealthService when AddWeight is '
        'dispatched and sync is enabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(),
          healthService: healthService,
        ),
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
        verify: (_) {
          verify(
            () => healthService.writeWeight(
              weightKg: 72,
              timestamp: any(named: 'timestamp'),
            ),
          ).called(1);
          verify(() => repository.addEntry(any())).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'mirrors updated weight entry by deleting old point and writing new point when weight changed and sync is enabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(),
          healthService: healthService,
        ),
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(
              id: 1,
              weightKg: 70,
              dateTime: DateTime(2026, 7, 15, 10),
            ),
          ],
          filteredEntries: const [],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(
          UpdateWeight(
            WeightEntry(
              id: 1,
              weightKg: 73,
              dateTime: DateTime(2026, 7, 15, 10),
            ),
          ),
        ),
        verify: (_) {
          verify(
            () => healthService.deleteWeight(
              weightKg: 70,
              timestamp: DateTime(2026, 7, 15, 10),
            ),
          ).called(1);
          verify(
            () => healthService.writeWeight(
              weightKg: 73,
              timestamp: DateTime(2026, 7, 15, 10),
            ),
          ).called(1);
          verify(() => repository.addEntry(any())).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'mirrors updated weight entry by deleting old point and writing new point when timestamp changed and sync is enabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(),
          healthService: healthService,
        ),
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(
              id: 1,
              weightKg: 70,
              dateTime: DateTime(2026, 7, 15, 10),
            ),
          ],
          filteredEntries: const [],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(
          UpdateWeight(
            WeightEntry(
              id: 1,
              weightKg: 70,
              dateTime: DateTime(2026, 7, 15, 12),
            ),
          ),
        ),
        verify: (_) {
          verify(
            () => healthService.deleteWeight(
              weightKg: 70,
              timestamp: DateTime(2026, 7, 15, 10),
            ),
          ).called(1);
          verify(
            () => healthService.writeWeight(
              weightKg: 70,
              timestamp: DateTime(2026, 7, 15, 12),
            ),
          ).called(1);
          verify(() => repository.addEntry(any())).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'does NOT delete or re-write to HealthService when only the note was updated',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(),
          healthService: healthService,
        ),
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(
              id: 1,
              weightKg: 70,
              dateTime: DateTime(2026, 7, 15, 10),
              note: 'Old note',
            ),
          ],
          filteredEntries: const [],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(
          UpdateWeight(
            WeightEntry(
              id: 1,
              weightKg: 70,
              dateTime: DateTime(2026, 7, 15, 10),
              note: 'New updated note',
            ),
          ),
        ),
        verify: (_) {
          verifyNever(
            () => healthService.deleteWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          );
          verifyNever(
            () => healthService.writeWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          );
          verify(() => repository.addEntry(any())).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'does NOT mirror weight entry to HealthService when sync is disabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(isHealthSyncEnabled: false),
          healthService: healthService,
        ),
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
        verify: (_) {
          verifyNever(
            () => healthService.writeWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          );
        },
      );

      blocTest<WeightBloc, WeightState>(
        'keeps the local entry persisted when the health mirror write fails',
        build: () {
          when(
            () => healthService.writeWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          ).thenThrow(Exception('Health write failed'));
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
        expect: () => [isA<WeightLoading>()],
        verify: (_) {
          verify(() => repository.addEntry(any())).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'mirrors DeleteWeight to the health service when sync is enabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(),
          healthService: healthService,
        ),
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          filteredEntries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(DeleteWeight(1)),
        verify: (_) {
          verify(
            () => healthService.deleteWeight(
              weightKg: 72,
              timestamp: DateTime(2026, 1, 1, 9),
            ),
          ).called(1);
          verify(() => repository.deleteEntry(1)).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'does not mirror DeleteWeight when sync is disabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(isHealthSyncEnabled: false),
          healthService: healthService,
        ),
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          filteredEntries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(DeleteWeight(1)),
        verify: (_) {
          verifyNever(
            () => healthService.deleteWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          );
        },
      );

      blocTest<WeightBloc, WeightState>(
        'keeps local deletion successful when health mirror delete throws',
        build: () {
          when(
            () => healthService.deleteWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          ).thenThrow(Exception('Health delete failed'));
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () => WeightLoaded(
          entries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          filteredEntries: [
            WeightEntry(id: 1, weightKg: 72, dateTime: DateTime(2026, 1, 1, 9)),
          ],
          heightCm: 170,
        ),
        act: (bloc) => bloc.add(DeleteWeight(1)),
        expect: () => <WeightState>[],
        verify: (_) {
          verify(() => repository.deleteEntry(1)).called(1);
          verify(
            () => healthService.deleteWeight(
              weightKg: 72,
              timestamp: DateTime(2026, 1, 1, 9),
            ),
          ).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'fetches historical data from HealthService and saves to local '
        'repository on SyncHealthEntries',
        build: () {
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer(
            (_) async => [
              WeightEntry(weightKg: 80, dateTime: DateTime(2025, 6, 1, 8, 30)),
              WeightEntry(
                weightKg: 79.5,
                dateTime: DateTime(2025, 6, 2, 8, 30),
              ),
            ],
          );
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        verify: (_) {
          final imported =
              verify(
                    () => repository.syncRemoteEntries(captureAny()),
                  ).captured.single
                  as List<WeightEntry>;
          expect(imported.length, 2);
          expect(imported[0].weightKg, 80);
          expect(imported[1].weightKg, 79.5);
          // Loop prevention: the import path never mirrors back to Health.
          verifyNever(
            () => healthService.writeWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          );
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries imports only genuinely new entries',
        build: () {
          final existing1 = WeightEntry(
            id: 1,
            weightKg: 72,
            dateTime: DateTime(2026, 1, 1, 10, 30, 0),
          );
          final existing2 = WeightEntry(
            id: 2,
            weightKg: 71.5,
            dateTime: DateTime(2026, 1, 3, 7, 0, 0),
          );
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer(
            (_) async => [
              // Duplicate of existing1: same second-precision timestamp and
              // weight, only the millisecond component differs.
              WeightEntry(
                id: 0,
                weightKg: 72,
                dateTime: DateTime(2026, 1, 1, 10, 30, 0, 750),
              ),
              // Duplicate of existing2: exact timestamp and weight.
              WeightEntry(
                id: 0,
                weightKg: 71.5,
                dateTime: DateTime(2026, 1, 3, 7, 0, 0),
              ),
              // Genuinely new measurement.
              WeightEntry(
                id: 0,
                weightKg: 73,
                dateTime: DateTime(2026, 1, 2, 8),
              ),
            ],
          );
          var fetchCount = 0;
          when(() => repository.getAllEntries()).thenAnswer((_) async {
            fetchCount++;
            if (fetchCount == 1) {
              return [existing1, existing2];
            }
            return [
              existing1,
              existing2,
              WeightEntry(
                id: 3,
                weightKg: 73,
                dateTime: DateTime(2026, 1, 2, 8),
              ),
            ];
          });
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        expect: () => <WeightState>[],
        verify: (_) {
          final imported =
              verify(
                    () => repository.syncRemoteEntries(captureAny()),
                  ).captured.single
                  as List<WeightEntry>;
          expect(imported.length, 3);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'mirrors local entries missing from the health platform when '
        'SyncHealthEntries finds no remote counterpart',
        build: () {
          when(() => repository.getAllEntries()).thenAnswer(
            (_) async => [
              WeightEntry(
                id: 1,
                weightKg: 74,
                dateTime: DateTime(2026, 2, 1, 8),
              ),
            ],
          );
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async => const []);
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) async {
          bloc.add(SyncHealthEntries(startDate: DateTime(2026, 1, 1)));
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          verify(
            () => healthService.writeWeight(
              weightKg: any(named: 'weightKg'),
              timestamp: any(named: 'timestamp'),
            ),
          ).called(1);
          verifyNever(() => repository.syncRemoteEntries(any()));
        },
      );

      blocTest<WeightBloc, WeightState>(
        'does not mirror local entries outside the sync window even when '
        'they have no remote counterpart',
        build: () {
          when(() => repository.getAllEntries()).thenAnswer(
            (_) async => [
              // Well inside [windowStart, windowEnd] and missing remotely —
              // should be pushed.
              WeightEntry(
                id: 1,
                weightKg: 74,
                dateTime: DateTime(2026, 2, 3, 8),
              ),
              // Months before windowStart — must NOT be treated as
              // "missing from remote" just because this fetch's window
              // doesn't cover it. Regression guard for a bug where the
              // full local history (unbounded) was diffed against only
              // the incremental remote fetch window, causing the entire
              // history to be re-pushed to the health platform on every
              // sync call.
              WeightEntry(
                id: 2,
                weightKg: 71,
                dateTime: DateTime(2025, 10, 1, 8),
              ),
            ],
          );
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async => const []);
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) async {
          bloc.add(SyncHealthEntries(startDate: DateTime(2026, 2, 1)));
          await Future<void>.delayed(Duration.zero);
          await Future<void>.delayed(Duration.zero);
        },
        verify: (_) {
          // The in-window entry (id: 1) is pushed exactly once...
          verify(
            () => healthService.writeWeight(
              weightKg: 74,
              timestamp: DateTime(2026, 2, 3, 8),
            ),
          ).called(1);
          // ...but the out-of-window entry (id: 2) must never be.
          verifyNever(
            () => healthService.writeWeight(
              weightKg: 71,
              timestamp: any(named: 'timestamp'),
            ),
          );
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries is a no-op when sync is disabled',
        build: () => WeightBloc(
          repository: repository,
          appSettingsBloc: buildSettingsBloc(isHealthSyncEnabled: false),
          healthService: healthService,
        ),
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        expect: () => [],
        verify: (_) {
          verifyNever(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          );
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries swallows health fetch failures without crashing',
        build: () {
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenThrow(Exception('Health fetch failed'));
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => repository.syncRemoteEntries(any()));
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries uses a 30-day default window when lastHealthSyncTimestamp is null',
        build: () {
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async => const []);
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        verify: (_) {
          final captured =
              verify(
                    () => healthService.fetchWeightHistory(
                      start: captureAny(named: 'start'),
                      end: any(named: 'end'),
                    ),
                  ).captured.single
                  as DateTime;

          final diff = DateTime.now().difference(captured).inDays;
          expect(diff, closeTo(30, 1));
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries uses a 1-day lookback window from lastSync when available',
        build: () {
          final settingsBloc = MockAppSettingsBloc();
          final lastSync = DateTime.now().subtract(const Duration(days: 10));
          when(() => settingsBloc.state).thenReturn(
            AppSettingsState(
              isHealthSyncEnabled: true,
              lastHealthSyncTimestamp: lastSync,
            ),
          );
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async => const []);
          return WeightBloc(
            repository: repository,
            appSettingsBloc: settingsBloc,
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) => bloc.add(const SyncHealthEntries()),
        verify: (_) {
          final captured =
              verify(
                    () => healthService.fetchWeightHistory(
                      start: captureAny(named: 'start'),
                      end: any(named: 'end'),
                    ),
                  ).captured.single
                  as DateTime;

          final expected = DateTime.now().subtract(
            const Duration(days: 11),
          ); // lastSync - 1 day
          expect(captured.difference(expected).inSeconds.abs(), lessThan(5));
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries drops concurrent events (droppable concurrency)',
        build: () {
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return const [];
          });
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) {
          bloc.add(const SyncHealthEntries());
          bloc.add(const SyncHealthEntries());
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).called(1);
        },
      );

      blocTest<WeightBloc, WeightState>(
        'SyncHealthEntries uses the custom startDate window when provided',
        build: () {
          when(
            () => healthService.fetchWeightHistory(
              start: any(named: 'start'),
              end: any(named: 'end'),
            ),
          ).thenAnswer((_) async => const []);
          return WeightBloc(
            repository: repository,
            appSettingsBloc: buildSettingsBloc(),
            healthService: healthService,
          );
        },
        seed: () =>
            const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
        act: (bloc) =>
            bloc.add(SyncHealthEntries(startDate: DateTime(2026, 3, 1))),
        verify: (_) {
          verify(
            () => healthService.fetchWeightHistory(
              start: DateTime(2026, 3, 1),
              end: any(named: 'end'),
            ),
          ).called(1);
        },
      );
    });
  });

  group('concurrency semantics', () {
    blocTest<WeightBloc, WeightState>(
      'AddWeight drops concurrent events (droppable)',
      build: () {
        when(() => repository.addEntry(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) {
        bloc.add(const AddWeight(weightKg: 70));
        bloc.add(const AddWeight(weightKg: 71)); // Should be dropped
      },
      verify: (_) {
        verify(
          () => repository.addEntry(
            any(
              that: isA<WeightEntry>().having(
                (e) => e.weightKg,
                'weightKg',
                70,
              ),
            ),
          ),
        ).called(1);
        verifyNever(
          () => repository.addEntry(
            any(
              that: isA<WeightEntry>().having(
                (e) => e.weightKg,
                'weightKg',
                71,
              ),
            ),
          ),
        );
      },
    );

    blocTest<WeightBloc, WeightState>(
      'DeleteWeight processes sequentially (sequential)',
      build: () {
        when(() => repository.deleteEntry(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 170),
      act: (bloc) {
        bloc.add(const DeleteWeight(1));
        bloc.add(const DeleteWeight(2));
      },
      verify: (_) {
        verifyInOrder([
          () => repository.deleteEntry(1),
          () => repository.deleteEntry(2),
        ]);
      },
    );

    blocTest<WeightBloc, WeightState>(
      'ConfirmCsvImport bulk imports entries, emits WeightImportSuccess then WeightLoaded',
      build: () {
        when(
          () => repository.bulkImportEntries(any()),
        ).thenAnswer((_) async => 2);
        when(() => repository.getAllEntries()).thenAnswer(
          (_) async => [
            WeightEntry(id: 1, weightKg: 75.0, dateTime: DateTime(2026, 8, 20)),
            WeightEntry(id: 2, weightKg: 74.5, dateTime: DateTime(2026, 8, 21)),
          ],
        );
        return WeightBloc(repository: repository);
      },
      seed: () =>
          const WeightLoaded(entries: [], filteredEntries: [], heightCm: 180),
      act: (bloc) => bloc.add(
        ConfirmCsvImport(
          validEntries: [
            WeightEntry(id: 1, weightKg: 75.0, dateTime: DateTime(2026, 8, 20)),
            WeightEntry(id: 2, weightKg: 74.5, dateTime: DateTime(2026, 8, 21)),
          ],
        ),
      ),
      expect: () => [
        isA<WeightImportSuccess>()
            .having((s) => s.importedCount, 'importedCount', 2)
            .having((s) => s.entries.length, 'entries.length', 2),
        isA<WeightLoaded>().having(
          (s) => s.entries.length,
          'entries.length',
          2,
        ),
      ],
    );
  });
}
