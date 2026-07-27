import 'dart:io';
import 'package:csv/csv.dart' as csv;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:share_plus/share_plus.dart';

/// A utility class for exporting and sharing weight data as a CSV file.
class CsvExporter {
  /// Generates a CSV file from [entries] and shares it via the system dialog.
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

  /// Generates a CSV formatted string from the given [entries].
  static String generateCsv(List<WeightEntry> entries, [double? heightCm]) {
    final List<List<dynamic>> rows = [
      ['ID', 'Data', 'Waga (kg)', 'BMI', 'Notatka'],
    ];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (final entry in entries) {
      final bmiString = (heightCm != null && heightCm > 0)
          ? WeightEntry.calculateBmi(
              entry.weightKg,
              heightCm / 100,
            ).toStringAsFixed(1)
          : (entry.bmi != null ? entry.bmi!.toStringAsFixed(1) : '');

      rows.add([
        entry.id,
        dateFormat.format(entry.dateTime),
        entry.weightKg.toStringAsFixed(1),
        bmiString,
        entry.note ?? '',
      ]);
    }

    return csv.ListToCsvConverter(eol: '\n').convert(rows);
  }
}
