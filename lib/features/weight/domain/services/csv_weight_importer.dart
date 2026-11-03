import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/csv_import_analysis.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Represents the result of validating a CSV file before import.
sealed class CsvAnalysisOutcome {
  const CsvAnalysisOutcome();
}

/// Contains a successful CSV analysis ready for preview.
final class CsvAnalysisSuccess extends CsvAnalysisOutcome {
  final CsvImportAnalysis analysis;

  /// Creates a successful analysis result.
  const CsvAnalysisSuccess(this.analysis);
}

/// Contains the reason a CSV analysis failed.
final class CsvAnalysisFailure extends CsvAnalysisOutcome {
  final CsvErrorType errorType;

  /// Creates a failed analysis result.
  const CsvAnalysisFailure(this.errorType);
}

/// Defines CSV analysis and confirmation without depending on filesystem APIs.
abstract interface class CsvWeightImporter {
  /// Analyzes the CSV file at [filePath] without persisting its entries.
  Future<CsvAnalysisOutcome> analyzeFile(String filePath);

  /// Persists the confirmed [entries] and returns the inserted row count.
  Future<int> confirmImport(List<WeightEntry> entries);
}
