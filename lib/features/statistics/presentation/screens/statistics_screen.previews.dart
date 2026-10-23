import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

/// Shows statistics with recent measurements in the light theme.
@Preview(
  name: 'Statistics - Loaded',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget statisticsScreenLoadedPreview() =>
    _statisticsScreenPreview(dashboardPreviewLoadedWeightState());

/// Shows statistics with recent measurements in the dark theme.
@Preview(
  name: 'Statistics - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget statisticsScreenDarkPreview() =>
    _statisticsScreenPreview(dashboardPreviewLoadedWeightState());

/// Shows statistics when no measurements have been recorded.
@Preview(
  name: 'Statistics - Empty',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget statisticsScreenEmptyPreview() => _statisticsScreenPreview(
  const WeightLoaded(entries: [], filteredEntries: []),
);

Widget _statisticsScreenPreview(WeightState weightState) =>
    withDashboardPreviewBlocs(
      settingsState: dashboardPreviewSettingsState,
      weightState: weightState,
      child: const StatisticsScreen(),
    );
