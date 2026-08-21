import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';

export 'package:balance/core/integrations/csv/csv_importer.dart'
    show CsvImportAnalysis;

/// Thrown when the selected CSV file exceeds [CsvImportService.maxFileSizeBytes].
class FileTooLargeException implements Exception {
  final int maxBytes;

  const FileTooLargeException({required this.maxBytes});

  @override
  String toString() =>
      'FileTooLargeException: file exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit';

  String get message => toString();
}

/// The result of picking and parsing a CSV file.
///
/// Aliased to [CsvImportAnalysis] so callers receive the full audit record
/// (valid entries, skipped-row count, and date range) from [pickAndImport].
typedef CsvImportResult = CsvImportAnalysis;

/// Picks a CSV file from the system file picker and parses its contents into weight entries.
class CsvImportService {
  /// Maximum allowed file size (5 MB) to guard against out-of-memory crashes.
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Opens the system file picker filtered to CSV files and parses the selected
  /// file via [CsvImporter].
  ///
  /// Validates the file size against [maxFileSizeBytes] and decodes the bytes
  /// using UTF-8 with [allowMalformed] to survive legacy character encodings.
  /// Strips a leading UTF-8 BOM (`\uFEFF`) before parsing.
  ///
  /// Returns `null` when the user cancels the picker or the selected file has
  /// no path. Throws [FileTooLargeException] when the file exceeds
  /// [maxFileSizeBytes]. Throws a [FormatException] when no valid weight-history
  /// header is found.
  Future<CsvImportResult?> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    final path = result?.files.single.path;
    if (path == null) return null;

    final file = File(path);
    if (file.lengthSync() > maxFileSizeBytes) {
      throw FileTooLargeException(maxBytes: maxFileSizeBytes);
    }

    final bytes = await file.readAsBytes();
    var content = utf8.decode(bytes, allowMalformed: true);

    // Strip UTF-8 BOM if present.
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    return CsvImporter.parse(content);
  }
}
