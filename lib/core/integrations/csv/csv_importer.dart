import 'dart:isolate';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Parses weight-history CSV content into [WeightEntry] entities on a background isolate.
///
/// ## CSV contract
/// The parser mirrors the `CsvExporter` output but is lenient about headers,
/// delimiters, and extra columns:
/// - Delimiter: comma by default; a tab or semicolon is auto-detected from
///   the header line.
/// - Header row: column names are matched case-insensitively. A date column
///   (`data`, `date`, `data_date`) and a weight column (`waga`, `waga (kg)`,
///   `weight`, `weight (kg)`, `weight_kg`, `waga_kg`) are required; a time
///   column (`czas`, `time`) and a note column (`notatka`, `komentarz`,
///   `note`, `komentarz_note`) are optional.
/// - Weight values are parsed as kilograms; a decimal comma is accepted.
/// - Dates accept `yyyy-MM-dd HH:mm`, `yyyy-MM-dd`, `dd.MM.yyyy`,
///   `dd/MM/yyyy`, or any ISO-8601 value supported by [DateTime.tryParse].
/// - Fields may be double-quoted per RFC 4180, with `""` as an escaped quote.
/// - Rows that cannot be parsed or fall outside the valid weight range
///   ([WeightEntry.minWeightKg] – [WeightEntry.maxWeightKg]) are skipped and
///   counted in the result.
///
/// Example of supported content:
/// ```
/// ID,Data,Weight (kg),Note
/// 1,2024-01-15 07:30,75.2,Morning measurement
/// 2,2024-01-16 07:30,75.0,
/// ```
class CsvImporter {
  /// The attempted date formats in order of precedence.
  static final List<DateFormat> _dateFormats = [
    DateFormat('yyyy-MM-dd HH:mm'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('dd/MM/yyyy'),
  ];

  /// Parses [csvContent] asynchronously on a background isolate.
  ///
  /// Runs synchronously inside [Isolate.run] so large files never block the
  /// UI thread. Returns the parsed [WeightEntry] entities together with the
  /// count of skipped invalid rows.
  ///
  /// Throws a [FormatException] when the content is empty or the header row
  /// is missing the required date and weight columns.
  static Future<({List<WeightEntry> entries, int skippedRows})> parse(
    String csvContent,
  ) async {
    return Isolate.run(() => _parseSync(csvContent));
  }

  /// Parses [csvContent] synchronously within the background isolate.
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
    String delimiter = ',';
    if (header.contains('\t')) {
      delimiter = '\t';
    } else if (header.contains(';')) {
      delimiter = ';';
    }

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

      // Fallback for ISO-8601 with time component (e.g. 2024-01-15 07:30 or Garmin 2026-05-30T00:00:00.000)
      date ??= DateTime.tryParse(dateString);

      if (date == null) {
        skippedRows++;
        continue;
      }

      // Parse time column if it exists (e.g. Garmin's "Czas")
      final timeString =
          columnIndex['czas'] != null && fields.length > columnIndex['czas']!
          ? fields[columnIndex['czas']!].trim()
          : null;

      if (timeString != null && timeString.isNotEmpty) {
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]);
          final minute = int.tryParse(timeParts[1]);
          if (hour != null && minute != null) {
            date = DateTime(date.year, date.month, date.day, hour, minute);
          }
        }
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
      } else if (normalized == 'czas' || normalized == 'time') {
        indices['czas'] = i;
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

  /// Splits a single CSV line into fields, honoring RFC 4180 double-quoting.
  ///
  /// A field may be wrapped in `"` quotes, and `""` inside a quoted span is
  /// unescaped to a single literal quote. The [delimiter] only separates
  /// fields outside quoted spans.
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
