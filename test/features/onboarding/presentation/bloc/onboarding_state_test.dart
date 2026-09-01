import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('OnboardingState Unit Tests', () {
    test('default constructor initializes standard defaults', () {
      const state = OnboardingState();

      expect(state.currentStepIndex, 0);
      expect(state.totalSteps, 6);
      expect(state.selectedUnit, MeasurementUnit.metric);
      expect(state.importedCsvEntries, isEmpty);
      expect(state.draftInitialWeight, isNull);
      expect(state.draftInitialTimestamp, isNull);
      expect(state.draftTargetWeight, isNull);
      expect(state.isHealthSyncRequested, isFalse);
      expect(state.isBiometricEnabled, isFalse);
      expect(state.latestImportedEntry, isNull);
    });

    test('latestImportedEntry resolves chronological newest entry', () {
      final oldEntry = WeightEntry(
        weightKg: 80.0,
        dateTime: DateTime(2026, 1, 1),
      );
      final newEntry = WeightEntry(
        weightKg: 78.0,
        dateTime: DateTime(2026, 2, 1),
      );

      final state = OnboardingState(importedCsvEntries: [oldEntry, newEntry]);

      expect(state.latestImportedEntry, newEntry);
    });

    test(
      'copyWith replaces specified values and supports explicit nulls with sentinel',
      () {
        final initialDate = DateTime(2026, 3, 1);
        final state = OnboardingState(
          currentStepIndex: 2,
          draftInitialWeight: 75.0,
          draftInitialTimestamp: initialDate,
          draftTargetWeight: 70.0,
          isHealthSyncRequested: true,
        );

        final updated = state.copyWith(
          currentStepIndex: 3,
          draftInitialWeight: null,
          draftTargetWeight: null,
          isHealthSyncRequested: false,
        );

        expect(updated.currentStepIndex, 3);
        expect(updated.draftInitialWeight, isNull);
        expect(updated.draftInitialTimestamp, initialDate);
        expect(updated.draftTargetWeight, isNull);
        expect(updated.isHealthSyncRequested, isFalse);
      },
    );

    test('props equality holds across identical instances', () {
      final date = DateTime(2026, 3, 1);
      final state1 = OnboardingState(
        currentStepIndex: 1,
        draftInitialWeight: 72.0,
        draftInitialTimestamp: date,
      );

      final state2 = OnboardingState(
        currentStepIndex: 1,
        draftInitialWeight: 72.0,
        draftInitialTimestamp: date,
      );

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
    });
  });
}
