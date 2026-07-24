import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Parses CSV file content and converts it into a list of [WeightEntry].
///
/// Expected CSV format (matches [CsvExporter] output):
/// ```
/// data,waga,komentarz
/// 2024-01-15,75.2,
/// 2024-01-16,75.0,Notowanie poranne
/// ```
///
/// Supports both comma and semicolon delimiters (auto-detected).
class CsvImporter {
  /// Parses [csvContent] and returns a list of [WeightEntry].
  ///
  /// Returns a list of successfully parsed entries, ignoring malformed rows.
  /// Throws [FormatException] if the CSV has no valid header row.
  static List<WeightEntry> parse(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw FormatException('CSV content is empty');
    }

    // Detect delimiter from header row
    final header = lines[0].toLowerCase();
    final delimiter = header.contains(';') ? ';' : ',';

    final headerFields = _parseCsvLine(header, delimiter);
    final columnIndex = _findColumnIndices(headerFields);

    if (columnIndex['data'] == null || columnIndex['waga'] == null) {
      throw FormatException('CSV missing required columns: "data" and "waga"');
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

      try {
        final date = DateTime.parse(dateString);
        final weight = double.parse(weightString);

        if (weight <= 0 || weight > 500) {
          skippedRows++;
          continue;
        }

        final note =
            columnIndex['komentarz'] != null &&
                fields.length > columnIndex['komentarz']!
            ? fields[columnIndex['komentarz']!].trim()
            : null;

        entries.add(WeightEntry(dateTime: date, weightKg: weight, note: note));
      } on FormatException {
        skippedRows++;
      }
    }

    if (skippedRows > 0) {
      // Log skipped rows count for debugging (no logging infrastructure available)
      // In a real app, would use a logger.
    }

    return entries;
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
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (inQuotes) {
        if (char == '"') {
          // Check for escaped quote
          if (i + 1 < line.length && line[i + 1] == '"') {
            current += '"';
            i++; // skip next quote
          } else {
            inQuotes = false;
          }
        } else {
          current += char;
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == delimiter) {
          fields.add(current);
          current = '';
        } else {
          current += char;
        }
      }
    }
    fields.add(current);
    return fields;
  }
}
