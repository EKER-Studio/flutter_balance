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
}
