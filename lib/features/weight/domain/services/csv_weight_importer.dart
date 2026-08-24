import 'dart:convert';
import 'dart:io';

import 'package:balance/core/database/database_module.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';

/// Sealed class representing the result of dry-run CSV analysis.
sealed class CsvAnalysisOutcome {
  const CsvAnalysisOutcome();
}

/// Analysis succeeded with valid entries ready for preview.
class CsvAnalysisSuccess extends CsvAnalysisOutcome {
  final CsvImportAnalysis analysis;
  const CsvAnalysisSuccess(this.analysis);
}

/// Analysis failed with a specific error reason.
class CsvAnalysisFailure extends CsvAnalysisOutcome {
  final CsvErrorType errorType;
  const CsvAnalysisFailure(this.errorType);
}

/// Domain service responsible for validating, parsing, and committing CSV weight records.
class CsvWeightImporter {
  final WeightRepository repository;

  /// Creates a [CsvWeightImporter] wrapping the repository for batch operations.
  const CsvWeightImporter({required this.repository});

  /// Performs dry-run analysis on the selected CSV file.
  Future<CsvAnalysisOutcome> analyzeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.lengthSync() > CsvImportService.maxFileSizeBytes) {
        return const CsvAnalysisFailure(CsvErrorType.fileTooLarge);
      }

      final bytes = await file.readAsBytes();
      var content = utf8.decode(bytes, allowMalformed: true);
      if (content.startsWith('\uFEFF')) content = content.substring(1);

      final analysis = await CsvImporter.parse(content);

      if (analysis.validEntries.isEmpty) {
        return const CsvAnalysisFailure(CsvErrorType.noEntries);
      }

      return CsvAnalysisSuccess(analysis);
    } on FormatException catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[CsvWeightImporter] FormatException during analyzeFile',
        fatal: false,
      );
      return const CsvAnalysisFailure(CsvErrorType.invalidFormat);
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[CsvWeightImporter] analyzeFile error',
        fatal: false,
      );
      return const CsvAnalysisFailure(CsvErrorType.invalidFormat);
    }
  }

  /// Commits confirmed entries to the database after capturing a rollback snapshot.
  Future<int> confirmImport(List<WeightEntry> entries) async {
    await DatabaseModule.createPreImportSnapshot();
    return repository.bulkImportEntries(entries);
  }
}
