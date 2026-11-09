import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/services/csv_exporter.dart';

/// Writes generated CSV content to a temporary file for sharing.
abstract final class CsvExportService {
  /// Writes [entries] to a timestamped CSV file in the temporary directory.
  static Future<File> exportToFile(List<WeightEntry> entries) async {
    final csvData = CsvExporter.generateCsv(entries);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/balance_export_$timestamp.csv');
    return file.writeAsString(csvData);
  }

  /// Best-effort deletion of a temporary export file.
  ///
  /// The file created by [exportToFile] lives in the app's cache/temp
  /// directory and is only needed while it is handed to the share sheet; once
  /// shared it should be removed so repeated exports do not accumulate files
  /// there. Failures are swallowed because cleanup is best-effort and must
  /// never surface to the user or break the export flow.
  static Future<void> deleteTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup; ignore failures.
    }
  }
}
