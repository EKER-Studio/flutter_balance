import 'package:flutter/material.dart';

/// Centralized semantic color tokens for feedback UI (snackbars, banners, and alerts).
abstract final class AppFeedbackTheme {
  // Success tokens
  static const Color successBackgroundLight = Color(0xFFE7F8ED);
  static const Color successBackgroundDark = Color(0xFF14291E);
  static const Color successForegroundLight = Color(0xFF156F35);
  static const Color successForegroundDark = Color(0xFF7CE38B);

  // Error tokens
  static const Color errorBackgroundLight = Color(0xFFFCE8E6);
  static const Color errorBackgroundDark = Color(0xFF2E1517);
  static const Color errorForegroundLight = Color(0xFFB3261E);
  static const Color errorForegroundDark = Color(0xFFF2B8B5);

  // Warning tokens
  static const Color warningBackgroundLight = Color(0xFFFEF7E0);
  static const Color warningBackgroundDark = Color(0xFF2A200B);
  static const Color warningForegroundLight = Color(0xFF7D5700);
  static const Color warningForegroundDark = Color(0xFFFFD56B);

  // Info tokens
  static const Color infoBackgroundLight = Color(0xFFE8F0FE);
  static const Color infoBackgroundDark = Color(0xFF121C2B);
  static const Color infoForegroundLight = Color(0xFF0A56D1);
  static const Color infoForegroundDark = Color(0xFFA8C7FA);
}
