import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';

/// Shows the settings screen in the light theme without native capabilities.
@Preview(
  name: 'Settings - Light',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget settingsScreenLightPreview() => _settingsScreenPreview();

/// Shows the settings screen in the dark theme without native capabilities.
@Preview(
  name: 'Settings - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget settingsScreenDarkPreview() => _settingsScreenPreview();

Widget _settingsScreenPreview() => withDashboardPreviewBlocs(
  settingsState: dashboardPreviewSettingsState,
  weightState: dashboardPreviewLoadedWeightState(),
  child: SettingsScreen(biometricAvailability: Future.value(false)),
);
