import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Utility class for exporting weight measurements as formatted CSV files.
class CsvExporter {
  /// Generates a CSV-formatted string from [entries].
  ///
  /// Takes a list of [WeightEntry] objects [entries] and an optional user height in cm [heightCm].
  /// Formats column headers as `['ID', 'Date', 'Weight (kg)', 'Note']` and formats timestamps as `yyyy-MM-dd HH:mm`.
  /// Returns a [String] containing the encoded CSV data rows separated by newlines (`\n`).
  static String generateCsv(List<WeightEntry> entries, [double? heightCm]) {
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

    return CsvEncoder(lineDelimiter: '\n').convert(rows);
  }
}
