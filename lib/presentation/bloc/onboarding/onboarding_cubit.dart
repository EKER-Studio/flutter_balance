import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_state.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';

/// Cubit managing the ephemeral state of the onboarding wizard.
///
/// Lives only while the wizard is on screen and holds temporary draft data
/// (step index, selected unit, imported CSV entries, draft weights). Persistent
/// outcomes are handed off to [WeightBloc] and [AppSettingsBloc] when a step
/// is confirmed or the wizard is completed.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Target for the persistent settings dispatched on completion.
  final AppSettingsBloc appSettingsBloc;

  /// Target for the weight entries dispatched during the wizard.
  final WeightBloc weightBloc;

  /// Creates an [OnboardingCubit] seeded with the wizard's starting values.
  ///
  /// @param appSettingsBloc Receives the persistent settings dispatched on completion.
  /// @param weightBloc Receives the weight entries dispatched on completion.
  /// @param totalSteps Total step count for the current build; the biometric
  ///   step is omitted on devices without credential support.
  /// @param initialUnit Unit preference already persisted in [AppSettingsBloc].
  /// @param initialTargetWeight Target weight already persisted, or `null`.
  OnboardingCubit({
    required this.appSettingsBloc,
    required this.weightBloc,
    int totalSteps = 6,
    MeasurementUnit initialUnit = MeasurementUnit.metric,
    double? initialTargetWeight,
  }) : super(
         OnboardingState(
           totalSteps: totalSteps,
           selectedUnit: initialUnit,
           draftTargetWeight: initialTargetWeight,
         ),
       );

  /// Advances to the next step; a no-op on the final step (completion is
  /// triggered explicitly via [completeOnboarding]).
  void nextStep() {
    if (state.currentStepIndex >= state.totalSteps - 1) return;
    goToStep(state.currentStepIndex + 1);
  }

  /// Goes back to the previous step; a no-op on the first step.
  void previousStep() {
    if (state.currentStepIndex <= 0) return;
    goToStep(state.currentStepIndex - 1);
  }

  /// Jumps to [index], ignoring out-of-range values.
  void goToStep(int index) {
    if (index < 0 || index >= state.totalSteps) return;
    emit(state.copyWith(currentStepIndex: index));
  }

  /// Stores the unit selected on the units & height step.
  void setUnit(MeasurementUnit unit) {
    emit(state.copyWith(selectedUnit: unit));
  }

  /// Stores the history parsed by the CSV import step.
  void setCsvEntries(List<WeightEntry> entries) {
    emit(state.copyWith(importedCsvEntries: List.unmodifiable(entries)));
  }

  /// Stores the initial weight (and its timestamp) confirmed by the user and
  /// dispatches the measurement to [WeightBloc] so it is persisted right away.
  void setInitialWeight({required double weightKg, DateTime? timestamp}) {
    weightBloc.add(AddWeight(weightKg: weightKg, dateTime: timestamp));
    emit(
      state.copyWith(
        draftInitialWeight: weightKg,
        draftInitialTimestamp: timestamp,
      ),
    );
  }

  /// Stores the target weight confirmed by the user (`null` clears it).
  void setTargetWeight(double? weightKg) {
    emit(state.copyWith(draftTargetWeight: weightKg));
  }

  /// Records whether the user connected health sync during onboarding.
  void toggleHealthSync(bool enabled) {
    emit(state.copyWith(isHealthSyncRequested: enabled));
  }

  /// Records whether the user enabled the biometric lock during onboarding.
  void toggleBiometric(bool enabled) {
    emit(state.copyWith(isBiometricEnabled: enabled));
  }

  /// Persists the remaining wizard data and completes onboarding.
  ///
  /// Bulk-imports any imported CSV history beyond the initial-weight entry
  /// (that entry is excluded by identity — it was already persisted via
  /// [setInitialWeight]) into [WeightBloc], then flushes the final persistent
  /// flags to [AppSettingsBloc]: [CompleteOnboarding] always, [ToggleHealthSync]
  /// and [UpdateBiometricLock] only when the user requested the integration but
  /// it is not yet persisted (idempotent — the integration steps persist their
  /// own toggles on interaction).
  void completeOnboarding() {
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
