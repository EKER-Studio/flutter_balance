import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_app_bar.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_biometric_lock.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_csv_import.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_health_sync.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_reminder_notification.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_target_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_welcome.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// A section widget that manages the page transitions, per-step callbacks, and progress bar for the onboarding wizard.
class OnboardingWizardContent extends StatefulWidget {
  final VoidCallback? onWizardCompleted;
  final CsvImportService? csvImportService;

  const OnboardingWizardContent({
    super.key,
    required this.onWizardCompleted,
    required this.csvImportService,
  });

  @override
  State<OnboardingWizardContent> createState() =>
      _OnboardingWizardContentState();
}

class _OnboardingWizardContentState extends State<OnboardingWizardContent> {
  final PageController _pageController = PageController();

  static const _stepNames = [
    'welcome',
    'units_height',
    'csv_import',
    'initial_weight',
    'target_weight',
    'reminder_notification',
    'health_sync',
    'biometric_lock',
  ];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<OnboardingBloc>();
    AppAnalytics.logOnboardingStarted(bloc.state.totalSteps);
    AppAnalytics.logOnboardingStepViewed(stepIndex: 0, stepName: _stepNames[0]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextStep({bool isSkipped = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final bloc = context.read<OnboardingBloc>();
    final currentIndex = bloc.state.currentStepIndex;
    final stepName = _stepNames[currentIndex];
    AppAnalytics.logOnboardingStepCompleted(
      stepIndex: currentIndex,
      stepName: stepName,
      isSkipped: isSkipped,
    );
    if (currentIndex + 1 >= bloc.state.totalSteps) {
      final settingsState = context.read<AppSettingsBloc>().state;
      AppAnalytics.logOnboardingCompleted(
        hasInitialWeight: bloc.state.draftInitialWeight != null,
        hasTargetWeight: bloc.state.draftTargetWeight != null,
        hasCsvData: bloc.state.importedCsvEntries.isNotEmpty,
        healthSyncEnabled: settingsState.isHealthSyncEnabled,
        biometricsEnabled: settingsState.isBiometricLockEnabled,
      );
      bloc.add(const OnboardingCompleted());
      widget.onWizardCompleted?.call();
    } else {
      bloc.add(const OnboardingStepAdvanced());
    }
  }

  void _handleWelcomeNext() {
    AppAnalytics.logOnboardingWelcomeContinueClicked();
    _goToNextStep();
  }

  void _handleUnitsHeightNext(MeasurementUnit unit, double heightCm) {
    AppAnalytics.logOnboardingUnitSelected(unit.name);
    AppAnalytics.logOnboardingHeightChanged();
    context.read<OnboardingBloc>().add(OnboardingUnitSelected(unit));

    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(UpdateMeasurementUnit(unit));
    settingsBloc.add(UpdateHeight(heightCm));

    context.read<WeightBloc>().add(UpdateUserHeight(heightCm));

    _goToNextStep();
  }

  void _handleCsvImported(List<WeightEntry> entries) {
    AppAnalytics.logOnboardingCsvImportSuccess(entries.length);
    context.read<OnboardingBloc>().add(OnboardingCsvImported(entries));
    _goToNextStep();
  }

  void _handleCsvSkipped() {
    AppAnalytics.logOnboardingCsvImportSkipped();
    _goToNextStep(isSkipped: true);
  }

  void _handleInitialWeightNext(double weightKg, DateTime timestamp) {
    AppAnalytics.logOnboardingInitialWeightSet();
    context.read<OnboardingBloc>().add(
      OnboardingInitialWeightSet(weightKg: weightKg, timestamp: timestamp),
    );
    _goToNextStep();
  }

  void _handleTargetWeightNext(
    double? targetWeightKg,
    WeightGoalMode goalMode,
  ) {
    if (targetWeightKg != null) {
      AppAnalytics.logOnboardingTargetWeightSet();
    } else {
      AppAnalytics.logOnboardingTargetWeightSkipped();
    }
    context.read<OnboardingBloc>().add(
      OnboardingTargetWeightSet(targetWeightKg),
    );
    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(TargetWeightChanged(targetWeightKg));
    settingsBloc.add(UpdateWeightGoalMode(goalMode));
    _goToNextStep(isSkipped: targetWeightKg == null);
  }

  void _handleReminderNext() {
    final notificationsEnabled = context
        .read<AppSettingsBloc>()
        .state
        .notificationsEnabled;
    _goToNextStep(isSkipped: !notificationsEnabled);
  }

  void _handleHealthSyncNext() {
    final healthEnabled = context
        .read<AppSettingsBloc>()
        .state
        .isHealthSyncEnabled;
    AppAnalytics.logOnboardingHealthSyncToggled(
      enabled: healthEnabled,
      permissionGranted: healthEnabled,
    );
    context.read<OnboardingBloc>().add(
      OnboardingHealthSyncToggled(healthEnabled),
    );
    _goToNextStep();
  }

  void _handleBiometricNext() {
    final biometricEnabled = context
        .read<AppSettingsBloc>()
        .state
        .isBiometricLockEnabled;
    AppAnalytics.logOnboardingBiometricsToggled(biometricEnabled);
    context.read<OnboardingBloc>().add(
      OnboardingBiometricsToggled(biometricEnabled),
    );
    _goToNextStep();
  }

  void _handleStepRewind() {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final currentIndex = context.read<OnboardingBloc>().state.currentStepIndex;
    if (currentIndex > 0) {
      AppAnalytics.logOnboardingStepBackClicked(
        fromStepIndex: currentIndex,
        toStepIndex: currentIndex - 1,
      );
    }
    context.read<OnboardingBloc>().add(const OnboardingStepRewound());
  }

  @override
  Widget build(BuildContext context) {
    final isBiometricSupported = context.select(
      (AppSettingsBloc bloc) => bloc.state.isBiometricSupported,
    );

    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.currentStepIndex != current.currentStepIndex,
      listener: (context, state) {
        final stepName = state.currentStepIndex < _stepNames.length
            ? _stepNames[state.currentStepIndex]
            : 'step_${state.currentStepIndex}';
        AppAnalytics.logOnboardingStepViewed(
          stepIndex: state.currentStepIndex,
          stepName: stepName,
        );
        _pageController.animateToPage(
          state.currentStepIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final steps = <Widget>[
            StepWelcome(onNext: _handleWelcomeNext),
            StepUnitsHeight(
              initialUnit: state.selectedUnit,
              initialHeightCm: context.read<AppSettingsBloc>().state.height,
              isCurrentPage: state.currentStepIndex == 1,
              onNext: _handleUnitsHeightNext,
            ),
            StepCsvImport(
              importService: widget.csvImportService,
              onFileImported: _handleCsvImported,
              onSkipped: _handleCsvSkipped,
            ),
            StepInitialWeight(
              unit: state.selectedUnit,
              initialWeightKg: state.latestImportedEntry?.weightKg,
              initialTimestamp: state.latestImportedEntry?.dateTime,
              onNext: _handleInitialWeightNext,
            ),
            StepTargetWeight(
              unit: state.selectedUnit,
              initialTargetWeightKg: state.draftTargetWeight,
              initialGoalMode: context
                  .read<AppSettingsBloc>()
                  .state
                  .weightGoalMode,
              initialWeightKg: state.draftInitialWeight,
              onNext: _handleTargetWeightNext,
            ),
            StepReminderNotification(onNext: _handleReminderNext),
            StepHealthSync(onNext: _handleHealthSyncNext),
            if (isBiometricSupported)
              StepBiometricLock(onNext: _handleBiometricNext),
          ];

          final isWelcomeStep = state.currentStepIndex == 0;
          final displayStep = state.currentStepIndex;
          final displayTotalSteps = state.totalSteps - 1;
          final progress = displayStep > 0
              ? (displayStep / displayTotalSteps)
              : 0.0;

          return PopScope(
            canPop: isWelcomeStep,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (!isWelcomeStep) {
                _handleStepRewind();
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: isWelcomeStep
                  ? null
                  : OnboardingAppBar(
                      displayStep: displayStep,
                      displayTotalSteps: displayTotalSteps,
                      progress: progress,
                      onBackPressed: _handleStepRewind,
                    ),
              body: SafeArea(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
