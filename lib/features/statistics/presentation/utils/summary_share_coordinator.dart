import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/statistics/presentation/utils/progress_summary_formatter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A coordinator handling the sharing of progress summaries via the system share sheet.
class SummaryShareCoordinator {
  const SummaryShareCoordinator._();

  /// Formats and shares the current progress summary.
  ///
  /// @param context Build context used for localization and origin frame coordinates.
  /// @param entries Full list of weight entries.
  /// @param targetWeight Optional goal weight.
  /// @param goalMode Active goal mode.
  /// @param unit Active measurement unit.
  /// @param heightCm Optional user height in cm.
  /// @param paceWindowDays Pace calculation window in days.
  static Future<void> shareProgress(
    BuildContext context, {
    required List<WeightEntry> entries,
    double? targetWeight,
    WeightGoalMode goalMode = WeightGoalMode.lose,
    required MeasurementUnit unit,
    double? heightCm,
    int paceWindowDays = 30,
  }) async {
    final l10n = AppLocalizations.of(context);
    final summaryText = ProgressSummaryFormatter.format(
      entries: entries,
      targetWeight: targetWeight,
      goalMode: goalMode,
      unit: unit,
      l10n: l10n,
      heightCm: heightCm,
      paceWindowDays: paceWindowDays,
    );

    if (summaryText.isEmpty) return;

    AppAnalytics.logStatisticsShareSummaryClicked(entryCount: entries.length);

    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await Share.share(
      summaryText,
      subject: l10n.totalProgress,
      sharePositionOrigin: originRect,
    );
  }
}
