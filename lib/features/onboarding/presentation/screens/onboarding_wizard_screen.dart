// Container screen for the initial onboarding wizard.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/widgets/sections/onboarding_wizard_content.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';

/// Container screen for the initial onboarding wizard.
///
/// Hosts the 6-step onboarding flow (extended with an optional biometric
/// step when the device supports credentials) and scopes an [OnboardingBloc]
/// to the wizard via BlocProvider. The bloc is seeded from the current
/// [AppSettingsBloc] state and wired to the [WeightBloc]/[AppSettingsBloc]
/// targets it hands persistent outcomes off to.
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
      child: OnboardingWizardContent(
        onWizardCompleted: onWizardCompleted,
        csvImportService: csvImportService,
      ),
    );
  }
}
