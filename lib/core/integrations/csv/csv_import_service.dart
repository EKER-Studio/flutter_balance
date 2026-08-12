import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// The outcome of picking and parsing a CSV file.
typedef CsvImportResult = ({List<WeightEntry> entries, int skippedRows});

/// A service that picks a CSV file from the system file picker and parses its
/// contents into [WeightEntry] entities entirely in memory.
class CsvImportService {
  /// Opens the system file picker filtered to CSV files and parses the
  /// selected file content via [CsvImporter].
  ///
  /// Returns `null` when the user cancels the picker. Throws
  /// a FormatException when the file is not a valid weight-history CSV.
  Future<CsvImportResult?> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    final path = result?.files.single.path;
    if (path == null) return null;

    final fileContent = await File(path).readAsString();
    return CsvImporter.parse(fileContent);
  }
}
