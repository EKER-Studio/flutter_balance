import 'package:flutter/material.dart';

/// Severity types determining background, text, and icon styling for [AppSnackBar].
enum SnackBarType { success, error, warning, info }

/// Utility class for presenting consistent, themed SnackBar notifications.
class AppSnackBar {
  /// Shows a styled SnackBar with the given [message], [type], and optional [icon] or [action].
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    IconData? icon,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    IconData defaultIcon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = isDark
            ? const Color(0xFF14291E)
            : const Color(0xFFE7F8ED);
        foregroundColor = isDark
            ? const Color(0xFF7CE38B)
            : const Color(0xFF156F35);
        defaultIcon = Icons.check_circle_outline_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = isDark
            ? const Color(0xFF2E1517)
            : const Color(0xFFFCE8E6);
        foregroundColor = isDark
            ? const Color(0xFFF2B8B5)
            : const Color(0xFFB3261E);
        defaultIcon = Icons.error_outline_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = isDark
            ? const Color(0xFF2A200B)
            : const Color(0xFFFEF7E0);
        foregroundColor = isDark
            ? const Color(0xFFFFD56B)
            : const Color(0xFF7D5700);
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = isDark
            ? const Color(0xFF121C2B)
            : const Color(0xFFE8F0FE);
        foregroundColor = isDark
            ? const Color(0xFFA8C7FA)
            : const Color(0xFF0A56D1);
        defaultIcon = Icons.info_outline_rounded;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Margin bottom 16 is typically enough, combined with floating behavior
        // flutter handles FAB/BottomNav avoidance automatically when using
        // SnackBarBehavior.floating if using a standard Scaffold.
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
