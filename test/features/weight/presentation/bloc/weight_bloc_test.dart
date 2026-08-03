import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;
  late StreamController<List<WeightEntry>> streamController;

  setUpAll(() {
    registerFallbackValue(WeightEntry(weightKg: 0, dateTime: DateTime(2000)));
  });

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    streamController = StreamController<List<WeightEntry>>.broadcast();

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => streamController.stream);
    when(() => repository.getAllEntries()).thenAnswer((_) async => []);
    when(() => repository.addEntry(any())).thenAnswer((_) async {});
    when(() => repository.deleteEntry(any())).thenAnswer((_) async {});

    HydratedBloc.storage = storage;
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
  });

  tearDown(() {
    streamController.close();
  });

  group('WeightBloc', () {
    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoading, WeightLoaded] after SubscribeToWeightChanges',
      build: () => WeightBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const SubscribeToWeightChanges());
        await Future(() {});
        streamController.add([]);
      },
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightLoaded>().having((s) => s.entries, 'entries', isEmpty),
      ],
    );

    blocTest<WeightBloc, WeightState>(
      'emits [WeightLoading, WeightError] when initial stream throws an error',
      build: () {
        when(() => repository.watchAllEntries()).thenAnswer(
          (_) => Stream.error(Exception('Database initialization failure')),
        );
        return WeightBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SubscribeToWeightChanges()),
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
        isA<WeightError>().having(
          (s) => s.errorType,
          'errorType',
          WeightErrorType.addEntryFailed,
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
      act: (bloc) => bloc.add(const DeleteWeight(1)),
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
      act: (bloc) => bloc.add(const ChangeChartFilter(TimePeriod.year)),
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

        bloc.add(const SubscribeToWeightChanges());
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
      bloc.add(const SubscribeToWeightChanges());
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

    test('close cancels stream subscription cleanly', () async {
      final bloc = WeightBloc(repository: repository);
      await bloc.close();
    });
  });
}
