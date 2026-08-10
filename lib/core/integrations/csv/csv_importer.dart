import 'dart:isolate';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A parser that converts CSV file content into a list of [WeightEntry].
///
/// Expected CSV format (matches [CsvExporter] output):
/// ```dart
/// ID,Data,Weight (kg),BMI,Note
/// 1,2024-01-15 07:30,75.2,23.1,Morning measurement
/// 2,2024-01-16 07:30,75.0,23.0,
/// ```
///
/// Supports both comma and semicolon delimiters (auto-detected).
class CsvImporter {
  /// Attempted date formats in order of precedence.
  static final List<DateFormat> _dateFormats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('dd/MM/yyyy'),
  ];

  /// Asynchronously parses [csvContent] on a background isolate to prevent UI thread jank.
  ///
  /// Passes the raw [csvContent] string across the isolate boundary and returns
  /// the parsed [WeightEntry] entities and count of skipped invalid rows.
  /// Throws a FormatException if the CSV has no valid header row or is corrupted.
  ///
  /// ```dart
  /// final result = await CsvImporter.parse(fileContent);
  /// // result.entries: valid weight entries, result.skippedRows: invalid rows
  /// ```
  static Future<({List<WeightEntry> entries, int skippedRows})> parse(
    String csvContent,
  ) async {
    return Isolate.run(() => _parseSync(csvContent));
  }

  /// Internal synchronous parsing logic executed within the background isolate.
  static ({List<WeightEntry> entries, int skippedRows}) _parseSync(
    String csvContent,
  ) {
    final lines = csvContent
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException('CSV content is empty');
    }

    // Detect delimiter from header row
    final header = lines[0].toLowerCase();
    final delimiter = header.contains(';') ? ';' : ',';

    final headerFields = _parseCsvLine(header, delimiter);
    final columnIndex = _findColumnIndices(headerFields);

    if (columnIndex['data'] == null || columnIndex['waga'] == null) {
      throw const FormatException(
        'CSV missing required columns: "Date" and "Weight"',
      );
    }

    final entries = <WeightEntry>[];
    int skippedRows = 0;

    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i], delimiter);

      if (fields.length < 2) {
        skippedRows++;
        continue;
      }

      final dateString = fields[columnIndex['data']!].trim();
      final weightString = fields[columnIndex['waga']!].trim();

      DateTime? date;
      for (final format in _dateFormats) {
        try {
          date = format.parseStrict(dateString);
          break;
        } on FormatException {
          // Try next pattern
        }
      }

      // Fallback for ISO-8601 with time component (e.g. 2024-01-15 07:30)
      date ??= DateTime.tryParse(dateString);

      if (date == null) {
        skippedRows++;
        continue;
      }

      final normalizedWeight = weightString.replaceAll(',', '.');
      final weight = double.tryParse(normalizedWeight);

      if (weight == null ||
          weight < WeightEntry.minWeightKg ||
          weight > WeightEntry.maxWeightKg) {
        skippedRows++;
        continue;
      }

      final note =
          columnIndex['komentarz'] != null &&
              fields.length > columnIndex['komentarz']!
          ? fields[columnIndex['komentarz']!].trim()
          : null;

      entries.add(WeightEntry(dateTime: date, weightKg: weight, note: note));
    }

    return (entries: entries, skippedRows: skippedRows);
  }

  /// Finds the column indices for required fields in the header.
  ///
  /// Supports both Polish (exported) and English headers:
  /// - Date: `Data`, `data`, `Date`, `date`, `data_date`
  /// - Weight: `Waga (kg)`, `waga`, `Weight`, `weight`, `waga_kg`
  /// - Note: `Notatka`, `komentarz`, `Note`, `note`, `komentarz_note`
  static Map<String, int?> _findColumnIndices(List<String> header) {
    final indices = <String, int?>{};
    for (int i = 0; i < header.length; i++) {
      final normalized = header[i].toLowerCase().trim();
      if (normalized == 'data' ||
          normalized == 'date' ||
          normalized == 'data_date') {
        indices['data'] = i;
      } else if (normalized == 'waga' ||
          normalized == 'waga (kg)' ||
          normalized == 'weight' ||
          normalized == 'weight (kg)' ||
          normalized == 'weight_kg' ||
          normalized == 'waga_kg') {
        indices['waga'] = i;
      } else if (normalized == 'notatka' ||
          normalized == 'komentarz' ||
          normalized == 'note' ||
          normalized == 'komentarz_note') {
        indices['komentarz'] = i;
      }
    }
    return indices;
  }

  /// Parses a single CSV line respecting quoted fields.
  static List<String> _parseCsvLine(String line, String delimiter) {
    final fields = <String>[];
    final current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++; // skip next quote
          } else {
            inQuotes = false;
          }
        } else {
          current.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == delimiter) {
          fields.add(current.toString());
          current.clear();
        } else {
          current.write(char);
        }
      }
    }
    fields.add(current.toString());
    return fields;
  }
}
