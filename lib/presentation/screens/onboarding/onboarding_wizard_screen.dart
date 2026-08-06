import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_biometric_lock.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_initial_weight.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_reminder_notification.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_target_weight.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_units_height.dart';

/// Main container screen for the multi-step initial onboarding setup wizard.
///
/// Manages step transitions, keyboard avoidance, screen orientation safety,
/// and hardware back button behavior via [PopScope].
class OnboardingWizardScreen extends StatefulWidget {
  /// Optional callback invoked upon completing all onboarding steps.
  final VoidCallback? onWizardCompleted;

  /// Creates an [OnboardingWizardScreen].
  const OnboardingWizardScreen({super.key, this.onWizardCompleted});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

/// Orchestrates the five onboarding steps and persists each step's choices
/// into [AppSettingsBloc] and [WeightBloc] as the user progresses.
///
/// Step order: Units & Height, Initial Weight, Target Weight (optional),
/// Daily Reminder (optional), Biometric Lock (optional, skipped when the
/// device does not support credentials). Completing the final step dispatches
/// [CompleteOnboarding] and invokes [OnboardingWizardScreen.onWizardCompleted].
class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  /// Total number of steps for the current build; the biometric step is
  /// omitted on devices without credential support.
  int _totalSteps = 5;

  late MeasurementUnit _selectedUnit;
  late double? _selectedHeightCm;
  double? _initialWeightKg;
  double? _targetWeightKg;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<AppSettingsBloc>().state;
    _selectedUnit = settingsState.measurementUnit;
    _selectedHeightCm = settingsState.height;
    _targetWeightKg = settingsState.targetWeight;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Animates the page view to [step] and updates the step indicator.
  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Persists the chosen [unit] and [heightCm], then advances.
  void _handleUnitsHeightNext(MeasurementUnit unit, double heightCm) {
    setState(() {
      _selectedUnit = unit;
      _selectedHeightCm = heightCm;
    });

    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(UpdateMeasurementUnit(unit));
    settingsBloc.add(UpdateHeight(heightCm));

    // Sync height into the weight BLoC before the initial-weight step
    // persists the measurement, otherwise its AddWeight guard rejects the
    // entry with a heightNotSet error on a fresh install (height is only ever
    // saved when settings are saved, or here in onboarding).
    context.read<WeightBloc>().add(UpdateUserHeight(heightCm));

    _goToNextStep();
  }

  /// Persists the initial [weightKg] measurement at [timestamp], then advances
  /// to the target-weight step.
  void _handleInitialWeightNext(double weightKg, DateTime timestamp) {
    setState(() {
      _initialWeightKg = weightKg;
    });

    try {
      context.read<WeightBloc>().add(
        AddWeight(weightKg: weightKg, dateTime: timestamp),
      );
    } catch (_) {
      // Safe fallback if WeightBloc is not provided in context (e.g. unit tests)
    }

    _goToNextStep();
  }

  /// Persists the chosen [targetWeightKg] (or `null` when skipped), then advances.
  void _handleTargetWeightNext(double? targetWeightKg) {
    setState(() {
      _targetWeightKg = targetWeightKg;
    });

    context.read<AppSettingsBloc>().add(TargetWeightChanged(targetWeightKg));
    _goToNextStep();
  }

  /// Advances past the notification step without additional action; the
  /// reminder state is already persisted by [StepReminderNotification].
  void _handleReminderNext() {
    _goToNextStep();
  }

  /// Advances past the biometric lock step; the choice is already persisted
  /// by [StepBiometricLock].
  void _handleBiometricNext() {
    _goToNextStep();
  }

  /// Advances to the next step, or completes onboarding when the current step
  /// is the final one.
  void _goToNextStep() {
    if (_currentStep + 1 >= _totalSteps) {
      _completeOnboarding();
    } else {
      _goToStep(_currentStep + 1);
    }
  }

  /// Dispatches [CompleteOnboarding] and notifies
  /// [OnboardingWizardScreen.onWizardCompleted].
  void _completeOnboarding() {
    context.read<AppSettingsBloc>().add(const CompleteOnboarding());
    widget.onWizardCompleted?.call();
  }

  /// Wraps a step in a scrollable, full-height column for small screens and
  /// keyboard inset safety.
  Widget _buildStepWrapper(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isBiometricSupported = context.select(
      (AppSettingsBloc bloc) => bloc.state.isBiometricSupported,
    );

    final steps = <Widget>[
      _buildStepWrapper(
        StepUnitsHeight(
          initialUnit: _selectedUnit,
          initialHeightCm: _selectedHeightCm,
          onNext: _handleUnitsHeightNext,
        ),
      ),
      _buildStepWrapper(
        StepInitialWeight(
          unit: _selectedUnit,
          onNext: _handleInitialWeightNext,
        ),
      ),
      _buildStepWrapper(
        StepTargetWeight(
          unit: _selectedUnit,
          initialTargetWeightKg: _targetWeightKg,
          initialWeightKg: _initialWeightKg,
          onNext: _handleTargetWeightNext,
        ),
      ),
      _buildStepWrapper(StepReminderNotification(onNext: _handleReminderNext)),
      if (isBiometricSupported)
        _buildStepWrapper(StepBiometricLock(onNext: _handleBiometricNext)),
    ];
    _totalSteps = steps.length;

    final progress = (_currentStep + 1) / steps.length;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _goToStep(_currentStep - 1);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            l10n.stepOf(_currentStep + 1, steps.length),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          centerTitle: true,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l10n.previousStepTooltip,
                  onPressed: () => _goToStep(_currentStep - 1),
                )
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
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
  }
}
