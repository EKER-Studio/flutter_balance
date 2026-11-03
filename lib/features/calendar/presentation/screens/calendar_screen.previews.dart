import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

/// Shows the calendar with recent measurements in the light theme.
@Preview(
  name: 'Calendar - Loaded',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget calendarScreenLoadedPreview() {
  final referenceDate = DateTime.now();
  return _calendarScreenPreview(
    dashboardPreviewLoadedWeightState(referenceDate: referenceDate),
    referenceDate: referenceDate,
  );
}

/// Shows the calendar with recent measurements in the dark theme.
@Preview(
  name: 'Calendar - Dark',
  group: 'Balance Screens',
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget calendarScreenDarkPreview() {
  final referenceDate = DateTime.now();
  return _calendarScreenPreview(
    dashboardPreviewLoadedWeightState(referenceDate: referenceDate),
    referenceDate: referenceDate,
  );
}

/// Shows the calendar with no recorded measurements.
@Preview(
  name: 'Calendar - Empty',
  group: 'Balance Screens',
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget calendarScreenEmptyPreview() => _calendarScreenPreview(
  WeightLoaded(entries: const [], filteredEntries: const []),
);

Widget _calendarScreenPreview(
  WeightState weightState, {
  DateTime? referenceDate,
}) {
  return withDashboardPreviewBlocs(
    settingsState: dashboardPreviewSettingsState,
    weightState: weightState,
    child: CalendarScreen(initialDate: referenceDate ?? DateTime.now()),
  );
}
