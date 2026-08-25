import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';

/// A modal dialog summarizing the result of a dry-run CSV analysis.
///
/// Displays the number of valid measurements found, the date range of those
/// measurements, and any skipped (invalid/unparseable) rows. Confirms the
/// final import operation.
class CsvImportPreviewDialog extends StatelessWidget {
  final CsvImportAnalysis analysis;

  const CsvImportPreviewDialog({super.key, required this.analysis});

  /// Displays the dialog and returns `true` if the user confirmed the import,
  /// or `false` if they cancelled or dismissed it.
  static Future<bool> show(
    BuildContext context, {
    required CsvImportAnalysis analysis,
  }) async {
    AppAnalytics.logDialogCsvAnalysisOpened(
      validCount: analysis.validEntries.length,
      invalidCount: analysis.skippedRowCount,
      duplicateCount: 0,
    );
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CsvImportPreviewDialog(analysis: analysis),
    );
    final confirmed = result ?? false;
    if (confirmed) {
      AppAnalytics.logDialogCsvAnalysisConfirmed(analysis.validEntries.length);
    } else {
      AppAnalytics.logSettingsCsvPreviewDialogCancelled();
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    );

    final String? dateRangeText;
    if (analysis.earliestDate != null && analysis.latestDate != null) {
      final start = dateFormat.format(analysis.earliestDate!);
      final end = dateFormat.format(analysis.latestDate!);
      dateRangeText = start == end
          ? start
          : l10n.csvPreviewDateRange(start, end);
    } else {
      dateRangeText = null;
    }

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(l10n.csvPreviewTitle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primaryContainer),
              ),
              child: Column(
                children: [
                  Text(
                    analysis.validEntries.length.toString(),
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (dateRangeText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateRangeText,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (analysis.skippedRowCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.csvPreviewSkippedRows(analysis.skippedRowCount),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.csvPreviewCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.csvPreviewConfirm),
        ),
      ],
    );
  }
}
