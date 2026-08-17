
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Exporting weight measurements as shareable CSV files.
///
//// A utility class for exporting weight measurements as formatted CSV files.
class CsvExporter {
  /// Generates a CSV-formatted string from [entries].
  ///
  /// The output uses a comma delimiter and `\n` line endings with RFC 4180
  /// quoting via [CsvEncoder]. Headers are `ID`, `Date`, `Weight (kg)`,
  /// `Note`; timestamps use `yyyy-MM-dd HH:mm`, weight values are formatted
  /// with one decimal in kilograms, and a missing note is encoded as an
  /// empty field.
  ///
  /// @param entries List of weight entry entities to encode.
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

  /// Writes [entries] as a timestamped CSV file in the system temp directory.
  ///
  /// The file is named `balance_export_<yyyyMMdd_HHmmss>.csv` and is ready for
  /// sharing via the `share_plus` plugin.
  ///
  /// @param entries List of weight entry entities to export.
  static Future<File> exportToFile(List<WeightEntry> entries) async {
    final csvData = generateCsv(entries);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/balance_export_$timestamp.csv');
    return file.writeAsString(csvData);
  }
}
