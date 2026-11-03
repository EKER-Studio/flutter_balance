import 'dart:convert';
import 'dart:io';

import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/services/csv_importer.dart';
import 'package:balance/features/weight/domain/services/csv_weight_importer.dart';

export 'package:balance/features/weight/domain/services/csv_weight_importer.dart';

/// Reads and analyzes CSV files before persisting confirmed weight entries.
class CsvFileWeightImporter implements CsvWeightImporter {
  /// Maximum allowed CSV file size.
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  final WeightRepository repository;

  /// Creates a file importer backed by [repository].
  const CsvFileWeightImporter({required this.repository});

  @override
  Future<CsvAnalysisOutcome> analyzeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.lengthSync() > maxFileSizeBytes) {
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
    } on FormatException catch (error, stackTrace) {
      AppCrashReporter.recordError(
        error,
        stackTrace,
        reason: '[CsvFileWeightImporter] CSV format analysis failed',
        fatal: false,
      );
      return const CsvAnalysisFailure(CsvErrorType.invalidFormat);
    } on FileSystemException catch (error, stackTrace) {
      AppCrashReporter.recordError(
        error,
        stackTrace,
        reason: '[CsvFileWeightImporter] CSV file access failed',
        fatal: false,
      );
      return const CsvAnalysisFailure(CsvErrorType.invalidFormat);
    } catch (error, stackTrace) {
      AppCrashReporter.recordError(
        error,
        stackTrace,
        reason: '[CsvFileWeightImporter] CSV analysis failed',
        fatal: false,
      );
      return const CsvAnalysisFailure(CsvErrorType.invalidFormat);
    }
  }

  @override
  Future<int> confirmImport(List<WeightEntry> entries) {
    return repository.bulkImportEntries(entries);
  }
}
