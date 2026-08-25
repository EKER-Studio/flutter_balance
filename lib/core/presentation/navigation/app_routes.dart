/// Centralized route paths, query parameter names, and deep-link URI builders.
abstract final class AppRoutes {
  /// Startup splash screen while initializing Isar and platform plugins.
  static const String splash = '/splash';

  /// Initialization error screen displayed when critical resources fail.
  static const String error = '/error';

  /// Multi-step onboarding wizard for first-time users.
  static const String onboarding = '/onboarding';

  /// Biometric shield screen requiring PIN/FaceID authentication.
  static const String shield = '/shield';

  /// Root dashboard tab: today's measurement, quick actions, and daily status.
  static const String today = '/today';

  /// History calendar tab with day-by-day records.
  static const String calendar = '/calendar';

  /// Trends, charts, BMI progress, and statistics tab.
  static const String statistics = '/statistics';

  /// Preferences, units, reminders, health sync, and backup settings tab.
  static const String settings = '/settings';

  /// Native privacy policy document screen.
  static const String privacyPolicy = '/privacy-policy';

  /// Constructs a deep link URI targeting the today screen with the add measurement dialog open.
  static String todayWithAddAction() =>
      '$today?${AppRouteParams.action}=${AppRouteParams.actionAdd}';

  /// Constructs a deep link URI targeting a specific date on the calendar tab.
  ///
  /// Reserved for upcoming deep link integration with interactive app widgets
  /// and scheduled system reminder notifications.
  static String calendarForDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$calendar?${AppRouteParams.date}=$year-$month-$day';
  }
}

/// Constant keys and standard values for route query parameters.
abstract final class AppRouteParams {
  /// Parameter key specifying a screen action to trigger upon navigation.
  static const String action = 'action';

  /// Action value indicating the add weight bottom sheet or dialog should open.
  static const String actionAdd = 'add';

  /// Parameter key specifying a target date filter in `YYYY-MM-DD` format.
  static const String date = 'date';
}
