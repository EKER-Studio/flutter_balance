import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/services/csv_import_service.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_csv_import.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_bloc.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_event.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_state.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_biometric_lock.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_health_sync.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_initial_weight.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_reminder_notification.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_target_weight.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_units_height.dart';

/// Container screen for the initial onboarding wizard.
///
/// Hosts the 6-step onboarding flow (extended with an optional biometric
/// step when the device supports credentials) and scopes an [OnboardingBloc]
/// to the wizard via [BlocProvider]. The bloc is seeded from the current
/// [AppSettingsBloc] state and wired to the [WeightBloc]/[AppSettingsBloc]
/// targets it hands persistent outcomes off to. Also handles keyboard
/// avoidance, screen orientation safety, and hardware back button behavior
/// via [PopScope].
class OnboardingWizardScreen extends StatelessWidget {
  /// Optional callback invoked upon completing all onboarding steps.
  final VoidCallback? onWizardCompleted;

  /// Service used by the CSV import step; defaults to a real
  /// [CsvImportService] and can be replaced with a fake in tests.
  final CsvImportService? csvImportService;

  /// Creates an [OnboardingWizardScreen].
  const OnboardingWizardScreen({
    super.key,
    this.onWizardCompleted,
    this.csvImportService,
  });

  @override
  Widget build(BuildContext context) {
    final isBiometricSupported = context.select(
      (AppSettingsBloc bloc) => bloc.state.isBiometricSupported,
    );

    return BlocProvider<OnboardingBloc>(
      create: (context) {
        final settingsState = context.read<AppSettingsBloc>().state;
        return OnboardingBloc(
          appSettingsBloc: context.read<AppSettingsBloc>(),
          weightBloc: context.read<WeightBloc>(),
          totalSteps: isBiometricSupported ? 7 : 6,
          initialUnit: settingsState.measurementUnit,
          initialTargetWeight: settingsState.targetWeight,
        )..add(const OnboardingStarted());
      },
      child: _OnboardingWizardContent(
        onWizardCompleted: onWizardCompleted,
        csvImportService: csvImportService,
      ),
    );
  }
}

/// Renders the onboarding steps and forwards every interaction to
/// [OnboardingBloc]; the only local state owned here is the [PageController].
///
/// Step mapping (index 0-5): Units & Height, CSV Import (optional), Initial
/// Weight, Target Weight (optional), Daily Reminder (optional), Health Sync
/// (optional). When the device supports credentials, a Biometric Lock step
/// (optional) is appended at index 6, so the wizard runs 6 or 7 steps in
/// total. Completing the final step dispatches [OnboardingCompleted] and
/// invokes [OnboardingWizardScreen.onWizardCompleted].
class _OnboardingWizardContent extends StatefulWidget {
  final VoidCallback? onWizardCompleted;
  final CsvImportService? csvImportService;

  /// Creates an [_OnboardingWizardContent] with [onWizardCompleted] and
  /// [csvImportService] forwarded from [OnboardingWizardScreen].
  const _OnboardingWizardContent({
    required this.onWizardCompleted,
    required this.csvImportService,
  });

  @override
  State<_OnboardingWizardContent> createState() =>
      _OnboardingWizardContentState();
}

class _OnboardingWizardContentState extends State<_OnboardingWizardContent> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Advances to the next step, or completes the wizard when the current step
  /// is the final one.
  ///
  /// The keyboard is dismissed before the page transition so the focus never
  /// leaks onto the next step.
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

  /// Stores the chosen [unit] and persists unit, height, and user height into
  /// the settings/weight BLoCs, then advances.
  ///
  /// Height is synced into the weight BLoC before the initial-weight step
  /// persists the measurement, otherwise its AddWeight guard rejects the
  /// entry with a heightNotSet error on a fresh install (height is only ever
  /// saved when settings are saved, or here in onboarding).
  void _handleUnitsHeightNext(MeasurementUnit unit, double heightCm) {
    context.read<OnboardingBloc>().add(OnboardingUnitSelected(unit));

    final settingsBloc = context.read<AppSettingsBloc>();
    settingsBloc.add(UpdateMeasurementUnit(unit));
    settingsBloc.add(UpdateHeight(heightCm));

    context.read<WeightBloc>().add(UpdateUserHeight(heightCm));

    _goToNextStep();
  }

  /// Stores the imported history and advances to the initial-weight step,
  /// which is pre-filled with the latest imported measurement.
  void _handleCsvImported(List<WeightEntry> entries) {
    context.read<OnboardingBloc>().add(OnboardingCsvImported(entries));
    _goToNextStep();
  }

  /// Advances to the initial-weight step without importing; the step stays
  /// blank and units chosen in step 1 remain untouched.
  void _handleCsvSkipped() {
    _goToNextStep();
  }

  /// Stores the initial [weightKg] measurement at [timestamp] as a draft; the
  /// measurement itself is persisted to [WeightBloc] by the bloc right away.
  void _handleInitialWeightNext(double weightKg, DateTime timestamp) {
    context.read<OnboardingBloc>().add(
      OnboardingInitialWeightSet(weightKg: weightKg, timestamp: timestamp),
    );
    _goToNextStep();
  }

  /// Stores the chosen [targetWeightKg] (or `null` when skipped) and persists
  /// it into [AppSettingsBloc], then advances.
  void _handleTargetWeightNext(double? targetWeightKg) {
    context.read<OnboardingBloc>().add(
      OnboardingTargetWeightSet(targetWeightKg),
    );
    context.read<AppSettingsBloc>().add(TargetWeightChanged(targetWeightKg));
    _goToNextStep();
  }

  /// Advances past the notification step without additional action; the
  /// reminder state is already persisted by [StepReminderNotification].
  void _handleReminderNext() {
    _goToNextStep();
  }

  /// Mirrors the already-persisted health sync flag into the wizard state and
  /// advances; the connection state is persisted by [StepHealthSync].
  void _handleHealthSyncNext() {
    context.read<OnboardingBloc>().add(
      OnboardingHealthSyncToggled(
        context.read<AppSettingsBloc>().state.isHealthSyncEnabled,
      ),
    );
    _goToNextStep();
  }

  /// Mirrors the already-persisted biometric lock flag into the wizard state
  /// and advances; the choice is persisted by [StepBiometricLock].
  void _handleBiometricNext() {
    context.read<OnboardingBloc>().add(
      OnboardingBiometricsToggled(
        context.read<AppSettingsBloc>().state.isBiometricLockEnabled,
      ),
    );
    _goToNextStep();
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
            _buildStepWrapper(
              StepUnitsHeight(
                initialUnit: state.selectedUnit,
                initialHeightCm: context.read<AppSettingsBloc>().state.height,
                onNext: _handleUnitsHeightNext,
              ),
            ),
            _buildStepWrapper(
              StepCsvImport(
                importService: widget.csvImportService,
                onFileImported: _handleCsvImported,
                onSkipped: _handleCsvSkipped,
              ),
            ),
            _buildStepWrapper(
              StepInitialWeight(
                unit: state.selectedUnit,
                initialWeightKg: state.latestImportedEntry?.weightKg,
                initialTimestamp: state.latestImportedEntry?.dateTime,
                onNext: _handleInitialWeightNext,
              ),
            ),
            _buildStepWrapper(
              StepTargetWeight(
                unit: state.selectedUnit,
                initialTargetWeightKg: state.draftTargetWeight,
                initialWeightKg: state.draftInitialWeight,
                onNext: _handleTargetWeightNext,
              ),
            ),
            _buildStepWrapper(
              StepReminderNotification(onNext: _handleReminderNext),
            ),
            _buildStepWrapper(
              StepHealthSync(
                onNext: _handleHealthSyncNext,
              ),
            ),
            if (isBiometricSupported)
              _buildStepWrapper(
                StepBiometricLock(onNext: _handleBiometricNext),
              ),
          ];

          final progress = (state.currentStepIndex + 1) / steps.length;

          return PopScope(
            canPop: state.currentStepIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (state.currentStepIndex > 0) {
                FocusManager.instance.primaryFocus?.unfocus();
                context.read<OnboardingBloc>().add(
                  const OnboardingStepRewound(),
                );
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                title: Text(
                  l10n.stepOf(state.currentStepIndex + 1, steps.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                centerTitle: true,
                    leading: state.currentStepIndex > 0
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: l10n.previousStepTooltip,
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              context.read<OnboardingBloc>().add(
                                const OnboardingStepRewound(),
                              );
                            },
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
        },
      ),
    );
  }
}
