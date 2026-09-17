import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  OnboardingBloc buildBloc({int totalSteps = 6}) {
    return OnboardingBloc(totalSteps: totalSteps);
  }

  group('OnboardingBloc', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStarted resets the state to initial values',
      build: buildBloc,
      seed: () => const OnboardingState(
        currentStepIndex: 3,
        selectedUnit: MeasurementUnit.imperial,
        isHealthSyncRequested: true,
      ),
      act: (bloc) => bloc.add(const OnboardingStarted()),
      expect: () => [
        const OnboardingState(
          currentStepIndex: 0,
          selectedUnit: MeasurementUnit.metric,
          isHealthSyncRequested: false,
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingUnitSelected updates selectedUnit',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const OnboardingUnitSelected(MeasurementUnit.imperial)),
      expect: () => [
        const OnboardingState(selectedUnit: MeasurementUnit.imperial),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingCsvImported updates importedCsvEntries',
      build: buildBloc,
      act: (bloc) {
        final entries = [
          WeightEntry(weightKg: 74.0, dateTime: DateTime(2026, 8, 1)),
        ];
        bloc.add(OnboardingCsvImported(entries));
      },
      expect: () => [
        isA<OnboardingState>().having(
          (s) => s.importedCsvEntries.length,
          'importedCsvEntries.length',
          1,
        ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingInitialWeightSet emits draft weight and timestamp',
      build: buildBloc,
      act: (bloc) => bloc.add(
        OnboardingInitialWeightSet(
          weightKg: 78.5,
          timestamp: DateTime(2026, 8, 20),
        ),
      ),
      expect: () => [
        isA<OnboardingState>()
            .having((s) => s.draftInitialWeight, 'draftInitialWeight', 78.5)
            .having(
              (s) => s.draftInitialTimestamp,
              'draftInitialTimestamp',
              DateTime(2026, 8, 20),
            ),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingTargetWeightSet updates draftTargetWeight',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingTargetWeightSet(72.0)),
      expect: () => [const OnboardingState(draftTargetWeight: 72.0)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingBiometricsToggled updates isBiometricEnabled flag',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingBiometricsToggled(true)),
      expect: () => [const OnboardingState(isBiometricEnabled: true)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingHealthSyncToggled(true) sets the isHealthSyncRequested flag',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingHealthSyncToggled(true)),
      expect: () => [const OnboardingState(isHealthSyncRequested: true)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingHealthSyncToggled(false) clears the isHealthSyncRequested flag',
      build: buildBloc,
      seed: () => const OnboardingState(isHealthSyncRequested: true),
      act: (bloc) => bloc.add(const OnboardingHealthSyncToggled(false)),
      expect: () => [const OnboardingState(isHealthSyncRequested: false)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepAdvanced advances from step 0 to step 1',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStepAdvanced()),
      expect: () => [const OnboardingState(currentStepIndex: 1)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepAdvanced is a no-op on the final step',
      build: () => buildBloc(totalSteps: 6),
      seed: () => const OnboardingState(currentStepIndex: 5),
      act: (bloc) => bloc.add(const OnboardingStepAdvanced()),
      expect: () => [],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepRewound goes back from step 1 to step 0',
      build: buildBloc,
      seed: () => const OnboardingState(currentStepIndex: 1),
      act: (bloc) => bloc.add(const OnboardingStepRewound()),
      expect: () => [const OnboardingState(currentStepIndex: 0)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepRewound is a no-op on the first step',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStepRewound()),
      expect: () => [],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingCompleted emits state with isCompleted set to true',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingCompleted()),
      expect: () => [const OnboardingState(isCompleted: true)],
    );

    test(
      'latestImportedEntry prioritizes today latest entry over older entries',
      () {
        final now = DateTime.now();
        final todayMorning = WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: DateTime(now.year, now.month, now.day, 8, 0),
        );
        final todayEvening = WeightEntry(
          id: 2,
          weightKg: 80.5,
          dateTime: DateTime(now.year, now.month, now.day, 20, 0),
        );
        final yesterday = WeightEntry(
          id: 3,
          weightKg: 81.0,
          dateTime: now.subtract(const Duration(days: 1)),
        );

        final state = OnboardingState(
          importedCsvEntries: [yesterday, todayMorning, todayEvening],
        );

        expect(state.latestImportedEntry, equals(todayEvening));
      },
    );

    test(
      'latestImportedEntry falls back to most recent entry if no today entry',
      () {
        final past1 = WeightEntry(
          id: 1,
          weightKg: 78.0,
          dateTime: DateTime(2024, 5, 10),
        );
        final past2 = WeightEntry(
          id: 2,
          weightKg: 77.0,
          dateTime: DateTime(2024, 6, 15),
        );

        final state = OnboardingState(importedCsvEntries: [past1, past2]);

        expect(state.latestImportedEntry, equals(past2));
      },
    );
  });
}
