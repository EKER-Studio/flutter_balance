import 'package:flutter/foundation.dart';

/// Defines the runtime environment configuration of the application.
enum AppEnvironment {
  /// Development environment for local builds, debugging, and feature development.
  dev,

  /// Production environment for live app releases.
  prod;

  /// Returns the current active runtime environment.
  ///
  /// Can be explicitly configured via `--dart-define=ENVIRONMENT=prod` (or `dev`).
  /// Defaults to [AppEnvironment.dev] when running in [kDebugMode], and [AppEnvironment.prod] otherwise.
  static AppEnvironment get current {
    const envString = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    if (envString == 'prod' || envString == 'production') {
      return AppEnvironment.prod;
    }
    if (envString == 'dev' || envString == 'development') {
      return AppEnvironment.dev;
    }
    return kDebugMode ? AppEnvironment.dev : AppEnvironment.prod;
  }

  /// Whether the active environment is development.
  static bool get isDev => current == AppEnvironment.dev;

  /// Whether the active environment is production.
  static bool get isProd => current == AppEnvironment.prod;

  /// The isolated notification channel ID for Android.
  String get notificationChannelId => this == AppEnvironment.dev
      ? 'daily_weight_reminders_dev_v1'
      : 'daily_weight_reminders_v2';
}
