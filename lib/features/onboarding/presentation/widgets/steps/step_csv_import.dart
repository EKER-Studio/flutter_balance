import 'package:flutter/material.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/csv_import_error_view.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/csv_import_idle_view.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/csv_import_loading_view.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/csv_import_success_view.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

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

      if (result.validEntries.isEmpty) {
        setState(() {
          _status = _CsvImportStatus.error;
          _isEmptyFileError = true;
        });
        return;
      }

      setState(() {
        _status = _CsvImportStatus.success;
        _entries = result.validEntries;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = _CsvImportStatus.error;
        _isEmptyFileError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final errorMessage = _isEmptyFileError
        ? l10n.importNoDataFound
        : l10n.csvImportError;

    return ClampedLayout(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: isLandscape ? 8.0 : 24.0,
      ),
      child: switch (_status) {
        _CsvImportStatus.idle => CsvImportIdleView(
            onPickFile: _handlePickFile,
            onSkipped: widget.onSkipped,
            isLandscape: isLandscape,
          ),
        _CsvImportStatus.loading => const CsvImportLoadingView(),
        _CsvImportStatus.success => CsvImportSuccessView(
            count: _entries.length,
            onContinue: () => widget.onFileImported(_entries),
            isLandscape: isLandscape,
          ),
        _CsvImportStatus.error => CsvImportErrorView(
            message: errorMessage,
            onRetry: _handlePickFile,
            isLandscape: isLandscape,
          ),
      },
    );
  }
}
