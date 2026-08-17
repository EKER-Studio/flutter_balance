import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// The result of picking and parsing a CSV file, containing parsed [WeightEntry] entities and a skip count.
typedef CsvImportResult = ({List<WeightEntry> entries, int skippedRows});

/// Picks a CSV file from the system file picker and parses its contents into [WeightEntry] entities.
class CsvImportService {
  /// Opens the system file picker filtered to CSV files and parses the selected file via [CsvImporter].
  ///
  /// Reads the file content as UTF-8. Returns `null` when the user cancels
  /// the picker. Throws a [FormatException] when the file is not a valid
  /// weight-history CSV.
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
