import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('OnboardingEvent equality', () {
    test('OnboardingStarted is equal to another OnboardingStarted', () {
      expect(const OnboardingStarted(), const OnboardingStarted());
    });

    test('OnboardingStepAdvanced and Rewound are distinct', () {
      expect(
        const OnboardingStepAdvanced(),
        isNot(const OnboardingStepRewound()),
      );
    });

    test('OnboardingUnitSelected compares by unit', () {
      expect(
        const OnboardingUnitSelected(MeasurementUnit.metric),
        const OnboardingUnitSelected(MeasurementUnit.metric),
      );
      expect(
        const OnboardingUnitSelected(MeasurementUnit.metric),
        isNot(const OnboardingUnitSelected(MeasurementUnit.imperial)),
      );
      expect(
        const OnboardingUnitSelected(MeasurementUnit.imperial).props,
        [MeasurementUnit.imperial],
      );
    });

    test('OnboardingCsvImported compares by entries list', () {
      final entries = [
        WeightEntry(weightKg: 75, dateTime: DateTime(2026, 1, 5)),
      ];
      expect(
        OnboardingCsvImported(entries),
        OnboardingCsvImported([entries.first]),
      );
      expect(
        OnboardingCsvImported(entries),
        isNot(OnboardingCsvImported(const [])),
      );
      expect(
        OnboardingCsvImported(entries).props,
        [entries],
      );
    });

    test('OnboardingInitialWeightSet compares by weight and timestamp', () {
      expect(
        const OnboardingInitialWeightSet(weightKg: 75.5),
        const OnboardingInitialWeightSet(weightKg: 75.5),
      );
      expect(
        const OnboardingInitialWeightSet(weightKg: 75.5),
        isNot(const OnboardingInitialWeightSet(weightKg: 76)),
      );
      expect(
        OnboardingInitialWeightSet(
          weightKg: 75.5,
          timestamp: DateTime(2026, 1, 5),
        ),
        isNot(const OnboardingInitialWeightSet(weightKg: 75.5)),
      );
      expect(
        const OnboardingInitialWeightSet(weightKg: 75.5).props,
        [75.5, null],
      );
    });

    test('OnboardingTargetWeightSet compares by nullable weight', () {
      expect(
        const OnboardingTargetWeightSet(70),
        const OnboardingTargetWeightSet(70),
      );
      expect(
        const OnboardingTargetWeightSet(null),
        OnboardingTargetWeightSet(null),
      );
      expect(
        const OnboardingTargetWeightSet(70),
        isNot(const OnboardingTargetWeightSet(null)),
      );
      expect(const OnboardingTargetWeightSet(70).props, [70]);
    });

    test('OnboardingHealthSyncToggled compares by enabled flag', () {
      expect(
        const OnboardingHealthSyncToggled(true),
        const OnboardingHealthSyncToggled(true),
      );
      expect(
        const OnboardingHealthSyncToggled(true),
        isNot(const OnboardingHealthSyncToggled(false)),
      );
      expect(const OnboardingHealthSyncToggled(true).props, [true]);
    });

    test('OnboardingBiometricsToggled compares by enabled flag', () {
      expect(
        const OnboardingBiometricsToggled(false),
        OnboardingBiometricsToggled(false),
      );
      expect(
        const OnboardingBiometricsToggled(false),
        isNot(const OnboardingBiometricsToggled(true)),
      );
      expect(const OnboardingBiometricsToggled(false).props, [false]);
    });

    test('OnboardingCompleted is equal to another OnboardingCompleted', () {
      expect(const OnboardingCompleted(), const OnboardingCompleted());
    });

    test('events with identical fields hash equally', () {
      expect(
        const OnboardingUnitSelected(MeasurementUnit.metric).hashCode,
        const OnboardingUnitSelected(MeasurementUnit.metric).hashCode,
      );
    });
  });
}