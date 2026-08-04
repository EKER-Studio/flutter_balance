import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_biometric_lock.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_initial_weight.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_reminder_notification.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_target_weight.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_units_height.dart';

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

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  late MeasurementUnit _selectedUnit;
  late double? _selectedHeightCm;
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

  void _handleUnitsHeightNext(MeasurementUnit unit, double heightCm) {
    setState(() {
      _selectedUnit = unit;
      _selectedHeightCm = heightCm;
    });

    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(UpdateMeasurementUnit(unit));
    settingsBloc.add(UpdateHeight(heightCm));

    // Sync height into the weight BLoC before the final step persists the
    // initial measurement, otherwise its AddWeight guard rejects the entry
    // with a heightNotSet error on a fresh install (height is only ever
    // stored in AppSettingsBloc during onboarding).
    context.read<WeightBloc>().add(UpdateUserHeight(heightCm));

    _goToStep(1);
  }

  void _handleTargetWeightNext(double? targetWeightKg) {
    setState(() {
      _targetWeightKg = targetWeightKg;
    });

    context.read<AppSettingsBloc>().add(TargetWeightChanged(targetWeightKg));
    _goToStep(2);
  }

  void _handleReminderNext() {
    _goToStep(3);
  }

  void _handleBiometricNext() {
    _goToStep(4);
  }

  void _handleInitialWeightComplete(double weightKg, DateTime timestamp) {
    // Log initial weight entry
    try {
      context.read<WeightBloc>().add(
        AddWeight(weightKg: weightKg, dateTime: timestamp),
      );
    } catch (_) {
      // Safe fallback if WeightBloc is not provided in context (e.g. unit tests)
    }

    // Complete onboarding setup
    context.read<AppSettingsBloc>().add(const CompleteOnboarding());

    widget.onWizardCompleted?.call();
  }

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
    final progress = (_currentStep + 1) / 5.0;

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
            l10n.stepOf(_currentStep + 1, 5),
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
            children: [
              _buildStepWrapper(
                StepUnitsHeight(
                  initialUnit: _selectedUnit,
                  initialHeightCm: _selectedHeightCm,
                  onNext: _handleUnitsHeightNext,
                ),
              ),
              _buildStepWrapper(
                StepTargetWeight(
                  unit: _selectedUnit,
                  initialTargetWeightKg: _targetWeightKg,
                  onNext: _handleTargetWeightNext,
                ),
              ),
              _buildStepWrapper(
                StepReminderNotification(
                  onNext: _handleReminderNext,
                ),
              ),
              _buildStepWrapper(
                StepBiometricLock(
                  onNext: _handleBiometricNext,
                ),
              ),
              _buildStepWrapper(
                StepInitialWeight(
                  unit: _selectedUnit,
                  onComplete: _handleInitialWeightComplete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
