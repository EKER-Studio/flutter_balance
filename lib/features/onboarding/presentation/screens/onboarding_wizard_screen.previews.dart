import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';

/// Shows the onboarding welcome step in the light theme.
@Preview(
  name: 'Onboarding - Welcome',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget onboardingWizardWelcomePreview() => _onboardingWizardPreview();

/// Shows the onboarding welcome step in the dark theme.
@Preview(
  name: 'Onboarding - Welcome Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget onboardingWizardWelcomeDarkPreview() => _onboardingWizardPreview();

Widget _onboardingWizardPreview() => withDashboardPreviewBlocs(
  settingsState: dashboardPreviewSettingsState,
  weightState: dashboardPreviewLoadedWeightState(),
  child: const OnboardingWizardScreen(),
);
