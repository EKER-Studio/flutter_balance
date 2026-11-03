import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Exports weight measurements as shareable CSV files.
class CsvExporter {
  /// Generates a CSV-formatted string from [entries].
  ///
  /// The output uses a comma delimiter and `\n` line endings with RFC 4180
  /// quoting via [CsvEncoder]. Headers are `ID`, `Date`, `Weight (kg)`,
  /// `Note`; timestamps use `yyyy-MM-dd HH:mm`, weight values are formatted
  /// with one decimal in kilograms, and a missing note is encoded as an
  /// empty field.
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
}
