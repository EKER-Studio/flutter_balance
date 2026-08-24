import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Reusable chart design tokens and styling helpers for `fl_chart`.
abstract final class AppChartTheme {
  /// Builds standard horizontal grid lines styled according to the active [ColorScheme].
  static FlGridData gridData({
    required ColorScheme colorScheme,
    required double horizontalInterval,
  }) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: horizontalInterval,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          strokeWidth: 1,
          dashArray: const [4, 4],
        );
      },
    );
  }

  /// Builds a transparent border configuration omitting bounding box strokes.
  static FlBorderData borderData() {
    return FlBorderData(show: false);
  }

  /// Linear gradient for the main weight line stroke.
  static LinearGradient lineGradient(Color primaryColor) {
    return LinearGradient(
      colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
    );
  }

  /// Area fill gradient beneath the line chart.
  static LinearGradient belowBarGradient(Color primaryColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withValues(alpha: 0.28),
        primaryColor.withValues(alpha: 0.0),
      ],
    );
  }
}
