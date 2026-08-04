import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Utility class for exporting weight measurements as formatted CSV files.
class CsvExporter {
  /// Generates a CSV-formatted string from [entries].
  ///
  /// Formats column headers as `['ID', 'Date', 'Weight (kg)', 'Note']` and formats timestamps as `yyyy-MM-dd HH:mm`.
  ///
  /// @param entries List of weight entry entities to encode.
  ///
  /// ```dart
  /// final csv = CsvExporter.generateCsv(entries);
  /// ```
  static String generateCsv(List<WeightEntry> entries) {
    final List<List<dynamic>> rows = [
      ['ID', 'Date', 'Weight (kg)', 'Note'],
    ];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final entry in entries) {
      rows.add([
        entry.id,
        dateFormat.format(entry.dateTime),
        entry.weightKg.toStringAsFixed(1),
        entry.note ?? '',
      ]);
    }

    return const CsvEncoder(lineDelimiter: '\n').convert(rows);
  }

  /// Writes [entries] as a temporary CSV file on disk.
  ///
  /// @param entries List of weight entry entities to export.
  ///
  /// Returns the created [File], suitable for sharing via `share_plus`.
  /// ```dart
  /// final file = await CsvExporter.exportToFile(entries);
  /// ```
  static Future<File> exportToFile(List<WeightEntry> entries) async {
    final csvData = generateCsv(entries);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/pure_weight_export_$timestamp.csv');
    return file.writeAsString(csvData);
  }
}
