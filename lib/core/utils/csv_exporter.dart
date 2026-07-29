import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:share_plus/share_plus.dart';

/// Utility class for exporting and sharing weight measurements as formatted CSV files.
class CsvExporter {
  /// Generates a CSV file from [entries] and shares it via the native system share sheet.
  ///
  /// Takes a mandatory list of [WeightEntry] records [entries] to export.
  /// Takes an optional [heightCm] value for user height reference.
  /// Writes the output file to the system temporary directory and invokes platform sharing.
  /// Returns a [Future] that completes when sharing dialog is invoked.
  /// May throw a file system error if temporary storage is unwriteable.
  static Future<void> exportAndShare(
    List<WeightEntry> entries, [
    double? heightCm,
  ]) async {
    final csvString = generateCsv(entries, heightCm);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/pure_weight_export.csv');
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'My PureWeight Data Export'),
    );
  }

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
