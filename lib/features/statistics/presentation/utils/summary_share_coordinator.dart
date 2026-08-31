import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
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
  /// @param unit Active measurement unit.
  static Future<void> shareProgress(
    BuildContext context, {
    required List<WeightEntry> entries,
    double? targetWeight,
    required MeasurementUnit unit,
  }) async {
    final l10n = AppLocalizations.of(context);
    final summaryText = ProgressSummaryFormatter.format(
      entries: entries,
      targetWeight: targetWeight,
      unit: unit,
      l10n: l10n,
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
