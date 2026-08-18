import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';

/// A modal dialog summarizing the result of a dry-run CSV analysis.
///
/// Displays the number of valid measurements found, the date range of those
/// measurements, and any skipped (invalid/unparseable) rows. Confirms the
/// final import operation.
class CsvImportPreviewDialog extends StatelessWidget {
  /// The analysis result containing entries and statistics.
  final CsvImportAnalysis analysis;

  /// Creates a [CsvImportPreviewDialog] with the given [analysis].
  const CsvImportPreviewDialog({super.key, required this.analysis});

  /// Displays the dialog and returns `true` if the user confirmed the import,
  /// or `false` if they cancelled or dismissed it.
  static Future<bool> show(
    BuildContext context, {
    required CsvImportAnalysis analysis,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CsvImportPreviewDialog(analysis: analysis),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final isLandscapePhone =
        MediaQuery.of(context).orientation == Orientation.landscape &&
        MediaQuery.sizeOf(context).height < 500;

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
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
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscapePhone ? 32 : 24,
        vertical: isLandscapePhone ? 8 : 24,
      ),
      icon: isLandscapePhone
          ? null
          : Icon(
              Icons.analytics_outlined,
              color: colorScheme.primary,
              size: 32,
            ),
      title: Text(l10n.csvPreviewTitle, textAlign: TextAlign.center),
      contentPadding: EdgeInsets.fromLTRB(
        24,
        isLandscapePhone ? 8 : 16,
        24,
        isLandscapePhone ? 12 : 20,
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Valid Entries Count & Date Range Card
            Container(
              padding: EdgeInsets.symmetric(
                vertical: isLandscapePhone ? 10 : 16,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primaryContainer),
              ),
              child: Column(
                children: [
                  Text(
                    analysis.validEntries.length.toString(),
                    style:
                        (isLandscapePhone
                                ? textTheme.headlineSmall
                                : textTheme.headlineMedium)
                            ?.copyWith(
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

            // Skipped Rows
            if (analysis.skippedRowCount > 0) ...[
              SizedBox(height: isLandscapePhone ? 8 : 12),
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
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.csvPreviewCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.csvPreviewConfirm),
        ),
      ],
    );
  }
}
