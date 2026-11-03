import 'package:balance/features/onboarding/domain/services/onboarding_completion_plan.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// Applies the actions derived from a completed onboarding draft.
final class OnboardingCompletionCoordinator {
  final AppSettingsBloc _settingsBloc;
  final WeightBloc _weightBloc;
  final void Function()? _onCompleted;

  /// Creates a coordinator for onboarding persistence and completion.
  OnboardingCompletionCoordinator({
    required AppSettingsBloc settingsBloc,
    required WeightBloc weightBloc,
    void Function()? onCompleted,
  }) : this._(settingsBloc, weightBloc, onCompleted);

  OnboardingCompletionCoordinator._(
    this._settingsBloc,
    this._weightBloc,
    this._onCompleted,
  );

  /// Persists the required actions for [state] and signals completion.
  void complete(OnboardingState state) {
    final settings = _settingsBloc.state;
    final plan = OnboardingCompletionPlan.fromDraft(
      importedEntries: state.importedCsvEntries,
      healthSyncRequested: state.isHealthSyncRequested,
      biometricLockRequested: state.isBiometricEnabled,
      healthSyncEnabled: settings.isHealthSyncEnabled,
      biometricLockEnabled: settings.isBiometricLockEnabled,
    );

    if (plan.entriesToImport.isNotEmpty) {
      _weightBloc.add(ImportWeightEntries(plan.entriesToImport));
    }
    if (plan.enableHealthSync) {
      _settingsBloc.add(const ToggleHealthSync(true));
    }
    if (plan.enableBiometricLock) {
      _settingsBloc.add(const UpdateBiometricLock(true));
    }
    _settingsBloc.add(const CompleteOnboarding());
    _onCompleted?.call();
  }
}
