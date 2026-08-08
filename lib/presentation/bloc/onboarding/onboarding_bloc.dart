import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_event.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';

/// BLoC managing the ephemeral state of the 6-step onboarding wizard via an
/// event-driven state machine.
///
/// Lives only while the wizard is on screen and holds temporary draft data
/// (step index, selected unit, imported CSV entries, draft weights, integration
/// toggles). Persistent outcomes are handed off to [WeightBloc] and
/// [AppSettingsBloc] when a step is confirmed or [OnboardingCompleted] is
/// dispatched.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  /// Target for the persistent settings dispatched on completion.
  final AppSettingsBloc appSettingsBloc;

  /// Target for the weight entries dispatched during the wizard.
  final WeightBloc weightBloc;

  final int _totalSteps;
  final MeasurementUnit _initialUnit;
  final double? _initialTargetWeight;

  /// Creates an [OnboardingBloc] seeded with the wizard's starting values.
  ///
  /// @param appSettingsBloc Receives the persistent settings dispatched on completion.
  /// @param weightBloc Receives the weight entries dispatched on completion.
  /// @param totalSteps Total step count for the current build; the biometric
  ///   step is omitted on devices without credential support.
  /// @param initialUnit Unit preference already persisted in [AppSettingsBloc].
  /// @param initialTargetWeight Target weight already persisted, or `null`.
  OnboardingBloc({
    required this.appSettingsBloc,
    required this.weightBloc,
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
    on<OnboardingStarted>(_onStarted);
    on<OnboardingStepAdvanced>(_onStepAdvanced);
    on<OnboardingStepRewound>(_onStepRewound);
    on<OnboardingUnitSelected>(_onUnitSelected);
    on<OnboardingCsvImported>(_onCsvImported);
    on<OnboardingInitialWeightSet>(_onInitialWeightSet);
    on<OnboardingTargetWeightSet>(_onTargetWeightSet);
    on<OnboardingHealthSyncToggled>(_onHealthSyncToggled);
    on<OnboardingBiometricsToggled>(_onBiometricsToggled);
    on<OnboardingCompleted>(_onCompleted);
  }

  /// Resets the wizard to a pristine state seeded from the constructor values.
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

  /// Stores the unit selected on the units & height step.
  void _onUnitSelected(
    OnboardingUnitSelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedUnit: event.unit));
  }

  /// Stores the history parsed by the CSV import step.
  void _onCsvImported(
    OnboardingCsvImported event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(importedCsvEntries: List.unmodifiable(event.entries)));
  }

  /// Stores the initial weight (and its timestamp) confirmed by the user and
  /// dispatches the measurement to [WeightBloc] so it is persisted right away.
  void _onInitialWeightSet(
    OnboardingInitialWeightSet event,
    Emitter<OnboardingState> emit,
  ) {
    weightBloc.add(
      AddWeight(weightKg: event.weightKg, dateTime: event.timestamp),
    );
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
  ///
  /// The draft is persisted to [AppSettingsBloc] only when still requested at
  /// [OnboardingCompleted] dispatch time.
  void _onHealthSyncToggled(
    OnboardingHealthSyncToggled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(isHealthSyncRequested: event.enabled));
  }

  /// Records the user's biometric lock request during onboarding.
  ///
  /// The draft is persisted to [AppSettingsBloc] only when still requested at
  /// [OnboardingCompleted] dispatch time.
  void _onBiometricsToggled(
    OnboardingBiometricsToggled event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(isBiometricEnabled: event.enabled));
  }

  /// Performs the final persistence of the wizard's draft data.
  ///
  /// Bulk-imports any imported CSV history beyond the initial-weight entry
  /// (that entry is excluded by identity — it was already persisted via
  /// [OnboardingInitialWeightSet]) into [WeightBloc], then flushes the final
  /// persistent flags to [AppSettingsBloc]: [CompleteOnboarding] always,
  /// [ToggleHealthSync] and [UpdateBiometricLock] only when the user requested
  /// the integration but it is not yet persisted (idempotent — the integration
  /// steps persist their own toggles on interaction).
  void _onCompleted(OnboardingCompleted event, Emitter<OnboardingState> emit) {
    final latest = state.latestImportedEntry;
    final remainingImported = latest == null
        ? const <WeightEntry>[]
        : state.importedCsvEntries.where((entry) => entry != latest).toList();
    if (remainingImported.isNotEmpty) {
      weightBloc.add(ImportWeightEntries(remainingImported));
    }

    final settingsState = appSettingsBloc.state;
    if (state.isHealthSyncRequested && !settingsState.isHealthSyncEnabled) {
      appSettingsBloc.add(const ToggleHealthSync(true));
    }
    if (state.isBiometricEnabled && !settingsState.isBiometricLockEnabled) {
      appSettingsBloc.add(const UpdateBiometricLock(true));
    }
    appSettingsBloc.add(const CompleteOnboarding());
  }
}
