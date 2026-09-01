import 'package:flutter/material.dart';
import 'package:balance/core/presentation/theme/app_feedback_theme.dart';

/// Severity types determining background, text, and icon styling for [AppSnackBar].
enum SnackBarType { success, error, warning, info }

/// Utility class for presenting consistent, themed SnackBar notifications.
class AppSnackBar {
  /// Shows a styled SnackBar with the given [message], [type], and optional [icon], [action], or [duration].
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    IconData? icon,
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    IconData defaultIcon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = isDark
            ? AppFeedbackTheme.successBackgroundDark
            : AppFeedbackTheme.successBackgroundLight;
        foregroundColor = isDark
            ? AppFeedbackTheme.successForegroundDark
            : AppFeedbackTheme.successForegroundLight;
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = isDark
            ? AppFeedbackTheme.errorBackgroundDark
            : AppFeedbackTheme.errorBackgroundLight;
        foregroundColor = isDark
            ? AppFeedbackTheme.errorForegroundDark
            : AppFeedbackTheme.errorForegroundLight;
        defaultIcon = Icons.error_outline_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = isDark
            ? AppFeedbackTheme.warningBackgroundDark
            : AppFeedbackTheme.warningBackgroundLight;
        foregroundColor = isDark
            ? AppFeedbackTheme.warningForegroundDark
            : AppFeedbackTheme.warningForegroundLight;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = isDark
            ? AppFeedbackTheme.infoBackgroundDark
            : AppFeedbackTheme.infoBackgroundLight;
        foregroundColor = isDark
            ? AppFeedbackTheme.infoForegroundDark
            : AppFeedbackTheme.infoForegroundLight;
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Bottom margin of 16 is sufficient; SnackBarBehavior.floating handles
        // FAB/BottomNav avoidance automatically.
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        action: action,
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: foregroundColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
