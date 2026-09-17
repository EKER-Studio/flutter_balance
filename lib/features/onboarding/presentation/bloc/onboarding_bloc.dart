import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';

/// BLoC managing the ephemeral state of the onboarding wizard via an
/// event-driven state machine.
///
/// Lives only while the wizard is on screen and holds temporary draft data
/// (step index, selected unit, imported CSV entries, draft weights, integration
/// toggles). State transitions emit UI state, and completion is signaled via
/// [OnboardingState.isCompleted].
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final int _totalSteps;
  final MeasurementUnit _initialUnit;
  final double? _initialTargetWeight;

  /// Creates an [OnboardingBloc] seeded with the wizard's starting values.
  ///
  /// [totalSteps] is the step count for the current build; the
  /// biometric step is omitted on devices without credential support.
  /// [initialUnit] is the unit preference already persisted in settings.
  /// [initialTargetWeight] is the target weight already persisted, or `null`.
  OnboardingBloc({
    int totalSteps = 6,
    MeasurementUnit initialUnit = MeasurementUnit.metric,
    double? initialTargetWeight,
  }) : _totalSteps = totalSteps,
       _initialUnit = initialUnit,
       _initialTargetWeight = initialTargetWeight,
       super(
         OnboardingState(
           totalSteps: totalSteps,
           selectedUnit: initialUnit,
           draftTargetWeight: initialTargetWeight,
         ),
       ) {
    on<OnboardingStarted>(_onStarted, transformer: restartable());
    on<OnboardingStepAdvanced>(_onStepAdvanced, transformer: droppable());
    on<OnboardingStepRewound>(_onStepRewound, transformer: droppable());
    on<OnboardingUnitSelected>(_onUnitSelected);
    on<OnboardingCsvImported>(_onCsvImported, transformer: droppable());
    on<OnboardingInitialWeightSet>(_onInitialWeightSet);
    on<OnboardingTargetWeightSet>(_onTargetWeightSet);
    on<OnboardingHealthSyncToggled>(_onHealthSyncToggled);
    on<OnboardingBiometricsToggled>(_onBiometricsToggled);
    on<OnboardingCompleted>(_onCompleted, transformer: droppable());
  }

  void _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) {
    emit(
      OnboardingState(
        totalSteps: _totalSteps,
        selectedUnit: _initialUnit,
        draftTargetWeight: _initialTargetWeight,
      ),
    );
  }

  /// Advances to the next step; a no-op on the final step (completion is
  /// triggered explicitly via [OnboardingCompleted]).
  void _onStepAdvanced(
    OnboardingStepAdvanced event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentStepIndex >= state.totalSteps - 1) return;
    emit(state.copyWith(currentStepIndex: state.currentStepIndex + 1));
  }

  /// Goes back to the previous step; a no-op on the first step.
  void _onStepRewound(
    OnboardingStepRewound event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.currentStepIndex <= 0) return;
    emit(state.copyWith(currentStepIndex: state.currentStepIndex - 1));
  }

  void _onUnitSelected(
    OnboardingUnitSelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedUnit: event.unit));
  }

  void _onCsvImported(
    OnboardingCsvImported event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(importedCsvEntries: List.unmodifiable(event.entries)));
  }

  /// Stores the initial weight (and its timestamp) confirmed by the user.
  void _onInitialWeightSet(
    OnboardingInitialWeightSet event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        draftInitialWeight: event.weightKg,
        draftInitialTimestamp: event.timestamp,
      ),
    );
  }

  /// Stores the target weight confirmed by the user (`null` clears it).
  void _onTargetWeightSet(
    OnboardingTargetWeightSet event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(draftTargetWeight: event.weightKg));
  }

  /// Records the user's health sync request during onboarding.
  void _onHealthSyncToggled(
    OnboardingHealthSyncToggled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(isHealthSyncRequested: event.enabled));
  }

  /// Records the user's biometric lock request during onboarding.
  void _onBiometricsToggled(
    OnboardingBiometricsToggled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(isBiometricEnabled: event.enabled));
  }

  /// Marks onboarding as completed in the state.
  void _onCompleted(OnboardingCompleted event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(isCompleted: true));
  }
}
