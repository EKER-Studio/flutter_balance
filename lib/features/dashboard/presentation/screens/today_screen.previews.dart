import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';

/// Shows the Today screen with realistic demo data in the light theme.
@Preview(
  name: 'Today Screen - Light',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget todayScreenLightPreview() => _todayScreenPreview();

/// Shows the Today screen with realistic demo data in the dark theme.
@Preview(
  name: 'Today Screen - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget todayScreenDarkPreview() => _todayScreenPreview();

Widget _todayScreenPreview() => withDashboardPreviewBlocs(
  settingsState: dashboardPreviewSettingsState,
  weightState: dashboardPreviewLoadedWeightState(),
  child: const TodayScreen(),
);
