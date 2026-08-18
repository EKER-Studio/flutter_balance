import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_csv_import.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_biometric_lock.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_health_sync.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_reminder_notification.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_target_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_welcome.dart';

/// Container screen for the initial onboarding wizard.
///
/// Hosts the 6-step onboarding flow (extended with an optional biometric
/// step when the device supports credentials) and scopes an [OnboardingBloc]
/// to the wizard via BlocProvider. The bloc is seeded from the current
/// [AppSettingsBloc] state and wired to the [WeightBloc]/[AppSettingsBloc]
/// targets it hands persistent outcomes off to. Also handles keyboard
/// avoidance, screen orientation safety, and hardware back button behavior
/// via PopScope.
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
          totalSteps: isBiometricSupported ? 8 : 7,
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

/// A widget that renders the onboarding steps and forwards every interaction
/// to [OnboardingBloc]; the only local state owned here is the PageController.
///
/// Page mapping: index 0 is the Welcome page, followed by Units & Height,
/// CSV Import (optional), Initial Weight, Target Weight (optional), Daily
/// Reminder (optional), and Health Sync (optional) at indices 1-6. When the
/// device supports credentials, a Biometric Lock step (optional) is appended
/// at index 7, so the wizard runs 7 or 8 pages in total. The Welcome page
/// counts as step 0, so the step indicator shows 1..6 or 1..7.
///
/// Navigation rules: the Next action dismisses the keyboard and either
/// advances one step (via [OnboardingStepAdvanced]) or, on the final step,
/// dispatches [OnboardingCompleted] and invokes
/// [OnboardingWizardScreen.onWizardCompleted]. Both the app bar back arrow
/// and the system back gesture (PopScope) rewind one step; on Welcome, where
/// there is nothing to rewind, back pops the screen instead. Per-step
/// validation is owned by each step widget: its Next action only fires with
/// valid input, so the wizard never advances through an invalid value.
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

  /// Advances from the welcome screen to the first configuration step.
  void _handleWelcomeNext() {
    context.read<OnboardingBloc>().add(const OnboardingStepAdvanced());
  }

  /// Stores the chosen [unit] and persists unit, height, and user height into
  /// the settings/weight BLoCs, then advances.
  ///
  /// Height is synced into the weight BLoC before the initial-weight step
  /// persists the measurement, otherwise its [AddWeight] guard rejects the
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

  /// Builds the progress app bar shown on every step except Welcome.
  ///
  /// Renders a modern, centered [LinearProgressIndicator] progress pill,
  /// with [Semantics] for screen readers, and a back arrow that unfocuses
  /// the keyboard and rewinds one step via [OnboardingStepRewound].
  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool isWelcomeStep,
    required int displayStep,
    required int displayTotalSteps,
    required double progress,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isWelcomeStep) {
      return const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      );
    }

    return AppBar(
      toolbarHeight: isLandscape ? 40.0 : 48.0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.previousStepTooltip,
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          context.read<OnboardingBloc>().add(const OnboardingStepRewound());
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8.0),
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 6.0),
          child: Semantics(
            label: l10n.stepOf(displayStep, displayTotalSteps),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4.0,
                borderRadius: BorderRadius.circular(4.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ),
    );
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

          // UX MATH: Welcome screen is step 0. Actual steps start from index 1.
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
                FocusManager.instance.primaryFocus?.unfocus();
                context.read<OnboardingBloc>().add(
                  const OnboardingStepRewound(),
                );
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: _buildAppBar(
                context,
                isWelcomeStep: isWelcomeStep,
                displayStep: displayStep,
                displayTotalSteps: displayTotalSteps,
                progress: progress,
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
