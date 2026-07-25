import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
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
        await Future.delayed(Duration.zero);
        streamController.add([]);
      },
      expect: () => [
        isA<WeightLoading>(),
        isA<WeightLoaded>().having((s) => s.entries, 'entries', isEmpty),
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
          WeightEntry(
            id: 1,
            weightKg: 70,
            bmi: 22.86,
            dateTime: DateTime(2025, 1, 1),
          ),
        ],
        filteredEntries: [
          WeightEntry(
            id: 1,
            weightKg: 70,
            bmi: 22.86,
            dateTime: DateTime(2025, 1, 1),
          ),
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
        // BMI is no longer persisted at creation time; it should be null.
        expect(entry.bmi, isNull);
      },
    );

    blocTest<WeightBloc, WeightState>(
      'emits WeightError on AddWeight when height is not set',
      build: () => WeightBloc(repository: repository),
      seed: () => const WeightInitial(),
      act: (bloc) => bloc.add(const AddWeight(weightKg: 72)),
      expect: () => [
        isA<WeightError>().having(
          (s) => s.message,
          'message',
          'Set your height first.',
        ),
      ],
    );
  });
}
