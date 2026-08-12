import 'package:flutter/material.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/core/clamped_layout.dart';

/// Internal state of the CSV import step.
enum _CsvImportStatus {
  /// Standard view with the description and the file picker button.
  idle,

  /// Parsing the selected file.
  loading,

  /// The file was parsed and [StepCsvImport.onFileImported] is pending.
  success,

  /// The selected file could not be parsed or contained no valid entries.
  error,
}

/// Optional onboarding step that lets new users seed their weight history
/// from an external CSV file.
///
/// The widget is decoupled from database persistence: parsed entries are held
/// in memory and handed to the parent wizard via [onFileImported].
class StepCsvImport extends StatefulWidget {
  /// Service used to pick and parse the CSV file; defaults to a real
  /// [CsvImportService] and can be replaced with a fake in tests.
  final CsvImportService? importService;

  /// Callback invoked with the parsed entries when the user confirms the
  /// import and proceeds to the next step.
  final void Function(List<WeightEntry> entries) onFileImported;

  /// Callback invoked when the user skips the step without importing.
  final VoidCallback onSkipped;

  /// Creates a [StepCsvImport] widget.
  const StepCsvImport({
    super.key,
    required this.onFileImported,
    required this.onSkipped,
    this.importService,
  });

  @override
  State<StepCsvImport> createState() => _StepCsvImportState();
}

class _StepCsvImportState extends State<StepCsvImport> {
  late final CsvImportService _importService;

  _CsvImportStatus _status = _CsvImportStatus.idle;
  List<WeightEntry> _entries = const [];

  /// Whether the error was caused by an empty result (no valid entries)
  /// rather than a parse failure; selects the error message in [build].
  bool _isEmptyFileError = false;

  @override
  void initState() {
    super.initState();
    _importService = widget.importService ?? CsvImportService();
  }

  /// Opens the file picker and parses the selected file, updating the step
  /// state on every outcome (cancel keeps the idle view).
  Future<void> _handlePickFile() async {
    setState(() {
      _status = _CsvImportStatus.loading;
      _isEmptyFileError = false;
    });

    try {
      final result = await _importService.pickAndImport();
      if (!mounted) return;

      if (result == null) {
        setState(() => _status = _CsvImportStatus.idle);
        return;
      }

      if (result.entries.isEmpty) {
        setState(() {
          _status = _CsvImportStatus.error;
          _isEmptyFileError = true;
        });
        return;
      }

      setState(() {
        _status = _CsvImportStatus.success;
        _entries = result.entries;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _CsvImportStatus.error;
        _isEmptyFileError = false;
      });
    }
  }

  /// Resets the step and re-opens the file picker after an error.
  void _handleRetry() {
    _handlePickFile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.csvImportStepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.csvImportStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: switch (_status) {
              _CsvImportStatus.idle => _buildIdle(theme, l10n),
              _CsvImportStatus.loading => _buildLoading(theme, l10n),
              _CsvImportStatus.success => _buildSuccess(theme, l10n),
              _CsvImportStatus.error => _buildError(theme, l10n),
            },
          ),
        ],
      ),
    );
  }

  /// Builds the idle view: the import tile and the next action.
  Widget _buildIdle(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: InkWell(
              key: const Key('csv_import_tile'),
              onTap: _handlePickFile,
              child: ListTile(
                leading: Icon(
                  Icons.upload_file,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  l10n.csvImportTileTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l10n.csvImportTileSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.csvFormatHintTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'ID, Date, Time (opt), Weight (kg), Note\n(lub: Data; Czas; Waga (kg))',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0),
          child: FilledButton(
            key: const Key('csv_import_next_button'),
            onPressed: widget.onSkipped,
            child: Text(l10n.next),
          ),
        ),
      ],
    );
  }

  /// Builds the loading view with a progress indicator.
  Widget _buildLoading(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16.0),
          Text(
            l10n.csvImportLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the success view with the imported count and a continue action.
  Widget _buildSuccess(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(28.0),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 16.0),
                Text(
                  l10n.csvImportSuccess(_entries.length),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0),
          child: FilledButton(
            key: const Key('csv_import_continue_button'),
            onPressed: () => widget.onFileImported(_entries),
            child: Text(l10n.csvImportContinueButton),
          ),
        ),
      ],
    );
  }

  /// Builds the inline error card with a friendly message and a retry action.
  Widget _buildError(ThemeData theme, AppLocalizations l10n) {
    final message = _isEmptyFileError
        ? l10n.importNoDataFound
        : l10n.csvImportError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(28.0),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(height: 16.0),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16.0),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton(
                    key: const Key('csv_import_retry_button'),
                    onPressed: _handleRetry,
                    child: Text(l10n.retry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
