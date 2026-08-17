// Theme mode preferences for the application.

/// An enumeration of the app's theme mode preferences.
///
//// Defaults to [AppThemeMode.system] when no preference has been stored yet.


enum AppThemeMode {
  /// Follows the system's appearance.
  system,

  /// Forces the light theme.
  light,

  /// Forces the dark theme.
  dark,
}
