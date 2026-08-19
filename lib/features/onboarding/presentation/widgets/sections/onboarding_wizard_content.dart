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
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// A section widget that manages the page transitions, per-step callbacks, and progress bar for the onboarding wizard.
class OnboardingWizardContent extends StatefulWidget {
  /// Optional callback invoked when the wizard completes the last step.
  final VoidCallback? onWizardCompleted;

  /// Service used by the CSV import step.
  final CsvImportService? csvImportService;

  /// Creates an [OnboardingWizardContent] widget.
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    FocusManager.instance.primaryFocus?.unfocus();
    final bloc = context.read<OnboardingBloc>();
    if (bloc.state.currentStepIndex + 1 >= bloc.state.totalSteps) {
      bloc.add(const OnboardingCompleted());
      widget.onWizardCompleted?.call();
    } else {
      bloc.add(const OnboardingStepAdvanced());
    }
  }

  void _handleWelcomeNext() {
    context.read<OnboardingBloc>().add(const OnboardingStepAdvanced());
  }

  void _handleUnitsHeightNext(MeasurementUnit unit, double heightCm) {
    context.read<OnboardingBloc>().add(OnboardingUnitSelected(unit));

    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(UpdateMeasurementUnit(unit));
    settingsBloc.add(UpdateHeight(heightCm));

    context.read<WeightBloc>().add(UpdateUserHeight(heightCm));

    _goToNextStep();
  }

  void _handleCsvImported(List<WeightEntry> entries) {
    context.read<OnboardingBloc>().add(OnboardingCsvImported(entries));
    _goToNextStep();
  }

  void _handleCsvSkipped() {
    _goToNextStep();
  }

  void _handleInitialWeightNext(double weightKg, DateTime timestamp) {
    context.read<OnboardingBloc>().add(
      OnboardingInitialWeightSet(weightKg: weightKg, timestamp: timestamp),
    );
    _goToNextStep();
  }

  void _handleTargetWeightNext(double? targetWeightKg) {
    context.read<OnboardingBloc>().add(
      OnboardingTargetWeightSet(targetWeightKg),
    );
    context.read<AppSettingsBloc>().add(TargetWeightChanged(targetWeightKg));
    _goToNextStep();
  }

  void _handleReminderNext() {
    _goToNextStep();
  }

  void _handleHealthSyncNext() {
    context.read<OnboardingBloc>().add(
      OnboardingHealthSyncToggled(
        context.read<AppSettingsBloc>().state.isHealthSyncEnabled,
      ),
    );
    _goToNextStep();
  }

  void _handleBiometricNext() {
    context.read<OnboardingBloc>().add(
      OnboardingBiometricsToggled(
        context.read<AppSettingsBloc>().state.isBiometricLockEnabled,
      ),
    );
    _goToNextStep();
  }

  void _handleStepRewind() {
    FocusManager.instance.primaryFocus?.unfocus();
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
