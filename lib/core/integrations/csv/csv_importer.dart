import 'dart:isolate';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Parses weight-history CSV content into [WeightEntry] entities on a background isolate.
///
/// ## CSV contract
/// The parser mirrors the `CsvExporter` output and supports third-party exports
/// such as Garmin Connect and Zepp Life (including hierarchical date groups):
/// - Delimiter: auto-detected comma, semicolon, or tab.
/// - Header row: matched case-insensitively with support for English and Polish
///   aliases. Pre-header metadata lines (e.g. `weight`) are skipped.
/// - Date / Time column aliases: `data`, `date`, `data_date`, `czas`, `time`,
///   `datetime`, `timestamp`.
/// - Weight column aliases: `ciężar`, `ciezar`, `waga`, `waga (kg)`, `waga_kg`,
///   `weight`, `weight (kg)`, `weight_kg`, `body mass`, `body_mass`.
/// - Note column aliases: `notatka`, `notatki`, `komentarz`, `note`, `notes`,
///   `komentarz_note`, `memo`.
/// - Weight values: sanitized to remove unit labels (`kg`, `lbs`, `g`), normalizes
///   decimal commas to dots, and ignores placeholders (`--`, `N/A`).
/// - Dates: supports hierarchical date group rows (e.g. `Cze 15, 2026`), 12-hour
///   AM/PM time formats (`9:26 AM`), 24-hour formats (`14:30`), Polish month
///   abbreviations, European formats (`dd.MM.yyyy`, `dd/MM/yyyy`), and ISO-8601.
class CsvImporter {
  /// The attempted standard date formats in order of precedence.
  static final List<DateFormat> _dateFormats = [
    DateFormat('yyyy-MM-dd HH:mm'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy/MM/dd'),
  ];

  /// Polish and English month names and abbreviations mapped to month numbers (1–12).
  static const Map<String, int> _monthMap = {
    'sty': 1,
    'styczeń': 1,
    'styczen': 1,
    'stycznia': 1,
    'jan': 1,
    'january': 1,
    'lut': 2,
    'luty': 2,
    'lutego': 2,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'marzec': 3,
    'marca': 3,
    'march': 3,
    'kwi': 4,
    'kwiecień': 4,
    'kwiecien': 4,
    'kwietnia': 4,
    'apr': 4,
    'april': 4,
    'maj': 5,
    'maja': 5,
    'may': 5,
    'cze': 6,
    'czerwiec': 6,
    'czerwca': 6,
    'jun': 6,
    'june': 6,
    'lip': 7,
    'lipiec': 7,
    'lipca': 7,
    'jul': 7,
    'july': 7,
    'sie': 8,
    'sierpień': 8,
    'sierpien': 8,
    'sierpnia': 8,
    'aug': 8,
    'august': 8,
    'wrz': 9,
    'wrzesień': 9,
    'wrzesien': 9,
    'września': 9,
    'wrzesnia': 9,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'paź': 10,
    'paz': 10,
    'październik': 10,
    'pazdziernik': 10,
    'października': 10,
    'pazdziernika': 10,
    'oct': 10,
    'october': 10,
    'lis': 11,
    'listopad': 11,
    'listopada': 11,
    'nov': 11,
    'november': 11,
    'gru': 12,
    'grudzień': 12,
    'grudzien': 12,
    'grudnia': 12,
    'dec': 12,
    'december': 12,
  };

  /// Parses [csvContent] asynchronously on a background isolate.
  ///
  /// Runs synchronously inside [Isolate.run] so large files never block the
  /// UI thread. Returns the parsed [WeightEntry] entities together with the
  /// count of skipped invalid rows.
  ///
  /// Throws a [FormatException] when the content is empty or no valid header
  /// containing both date and weight columns is found.
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

    // Step 1: Scan lines for a valid header row containing both Date and Weight columns
    int headerIndex = -1;
    String delimiter = ',';
    Map<String, int?> columnIndex = {};
    int headerColumnCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final delim in [',', ';', '\t']) {
        final fields = _parseCsvLine(line, delim);
        final cols = _findColumnIndices(fields);
        if (cols['data'] != null && cols['waga'] != null) {
          headerIndex = i;
          delimiter = delim;
          columnIndex = cols;
          headerColumnCount = fields.length;
          break;
        }
      }
      if (headerIndex != -1) break;
    }

    if (headerIndex == -1) {
      throw const FormatException(
        'CSV missing required columns: "Date" and "Weight"',
      );
    }

    final dataCol = columnIndex['data']!;
    final wagaCol = columnIndex['waga']!;
    final czasCol = columnIndex['czas'];
    final noteCol = columnIndex['komentarz'];

    final entries = <WeightEntry>[];
    int skippedRows = 0;
    DateTime? currentDateContext;

    // Step 2: Iterate through rows below the header
    for (int i = headerIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      var fields = _parseCsvLine(line, delimiter);

      if (fields.length < 2) {
        skippedRows++;
        continue;
      }

      // Check for hierarchical date header row (e.g. "Cze 15, 2026,,,,,,,")
      final lineWithoutTrailingDelims = line
          .replaceAll(RegExp(r'[,;\t]+$'), '')
          .trim();
      final dateFromTrimmedLine = _parseDate(lineWithoutTrailingDelims);
      if (dateFromTrimmedLine != null) {
        currentDateContext = dateFromTrimmedLine;
        continue;
      }

      // Repair unquoted decimal comma in comma-delimited rows (e.g. "...,78,5 kg,...")
      if (delimiter == ',' &&
          wagaCol < fields.length - 1 &&
          fields.length > headerColumnCount) {
        final wagaPart1 = fields[wagaCol].trim();
        final wagaPart2 = fields[wagaCol + 1].trim();
        if (RegExp(r'^\d+$').hasMatch(wagaPart1) &&
            RegExp(
              r'^\d+(\s*(kg|lbs|g))?$',
              caseSensitive: false,
            ).hasMatch(wagaPart2)) {
          final merged = '$wagaPart1.$wagaPart2';
          if (_cleanAndParseWeight(merged) != null) {
            fields = [
              ...fields.sublist(0, wagaCol),
              merged,
              if (wagaCol + 2 < fields.length) ...fields.sublist(wagaCol + 2),
            ];
          }
        }
      }

      final maxRequiredCol = math.max(dataCol, wagaCol);
      if (fields.length <= maxRequiredCol) {
        skippedRows++;
        continue;
      }

      final dateOrTimeRaw = fields[dataCol].trim();
      final weightRaw = fields[wagaCol].trim();

      // Check if this is a date group row where fields were split but weight is placeholder/empty
      final isPlaceholderWeight = _isPlaceholderOrEmpty(weightRaw);
      final parsedDirectDate = _parseDate(dateOrTimeRaw);

      if (parsedDirectDate != null && isPlaceholderWeight) {
        currentDateContext = parsedDirectDate;
        continue;
      }

      // Parse sanitized weight value
      final weight = _cleanAndParseWeight(weightRaw);
      if (weight == null) {
        skippedRows++;
        continue;
      }

      DateTime? entryDateTime;

      // Case A: Separate time column present (dataCol != czasCol)
      if (czasCol != null && czasCol != dataCol && fields.length > czasCol) {
        final timeRaw = fields[czasCol].trim();
        var datePart = parsedDirectDate ?? _parseDate(dateOrTimeRaw);
        if (datePart == null && currentDateContext != null) {
          datePart = currentDateContext;
        }

        if (datePart != null) {
          final timePart = _parseTime(timeRaw);
          if (timePart != null) {
            entryDateTime = DateTime(
              datePart.year,
              datePart.month,
              datePart.day,
              timePart.hour,
              timePart.minute,
            );
          } else {
            entryDateTime = datePart;
          }
        }
      }

      // Case B: Combined date/time in dataCol or time string in hierarchical format
      if (entryDateTime == null) {
        if (parsedDirectDate != null) {
          entryDateTime = parsedDirectDate;
          currentDateContext = parsedDirectDate;
        } else {
          final timePart = _parseTime(dateOrTimeRaw);
          if (timePart != null && currentDateContext != null) {
            entryDateTime = DateTime(
              currentDateContext.year,
              currentDateContext.month,
              currentDateContext.day,
              timePart.hour,
              timePart.minute,
            );
          }
        }
      }

      if (entryDateTime == null) {
        skippedRows++;
        continue;
      }

      final note = (noteCol != null && fields.length > noteCol)
          ? fields[noteCol].trim()
          : null;

      entries.add(
        WeightEntry(
          dateTime: entryDateTime,
          weightKg: weight,
          note: (note != null && note.isNotEmpty)
              ? note
              : (noteCol != null && fields.length > noteCol ? '' : null),
        ),
      );
    }

    return (entries: entries, skippedRows: skippedRows);
  }

  /// Tests whether [raw] represents an empty value or placeholder symbol.
  static bool _isPlaceholderOrEmpty(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed == '--' ||
        trimmed == '-' ||
        trimmed.toLowerCase() == 'n/a' ||
        trimmed.toLowerCase() == 'na' ||
        trimmed.toLowerCase() == 'null') {
      return true;
    }
    return false;
  }

  /// Sanitizes and parses a weight string, returning null if invalid or outside limits.
  static double? _cleanAndParseWeight(String raw) {
    if (_isPlaceholderOrEmpty(raw)) return null;

    var cleaned = raw.trim();
    cleaned = cleaned.replaceAll(
      RegExp(r'\s*(kg|kgs|lbs|lb|g)\b', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(',', '.').trim();
    final weight = double.tryParse(cleaned);
    if (weight == null ||
        weight < WeightEntry.minWeightKg ||
        weight > WeightEntry.maxWeightKg) {
      return null;
    }
    return weight;
  }

  /// Parses 12-hour (with AM/PM) or 24-hour time strings.
  static ({int hour, int minute})? _parseTime(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final amPm = match.group(4)?.toLowerCase();

    if (amPm != null) {
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour: hour, minute: minute);
  }

  /// Parses date strings supporting standard formats, ISO-8601, and Polish/English month names.
  static DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    for (final format in _dateFormats) {
      try {
        return format.parseStrict(trimmed);
      } on FormatException {
        // Try next format
      }
    }

    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) return isoParsed;

    // Pattern: "Month Day, Year" (e.g. "Cze 15, 2026" or "Jun 15, 2026 9:26 AM")
    final mdyMatch = RegExp(
      r'^([a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]+)\s+(\d{1,2})(?:,|\.)?\s+(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (mdyMatch != null) {
      final monthStr = mdyMatch.group(1)!.toLowerCase();
      final month = _monthMap[monthStr];
      final day = int.tryParse(mdyMatch.group(2)!);
      final year = int.tryParse(mdyMatch.group(3)!);

      if (month != null && day != null && year != null) {
        if (day >= 1 && day <= 31 && year >= 1900 && year <= 2200) {
          var hour = 0;
          var minute = 0;
          if (mdyMatch.group(4) != null && mdyMatch.group(5) != null) {
            hour = int.parse(mdyMatch.group(4)!);
            minute = int.parse(mdyMatch.group(5)!);
            final amPm = mdyMatch.group(7)?.toLowerCase();
            if (amPm == 'pm' && hour < 12) hour += 12;
            if (amPm == 'am' && hour == 12) hour = 0;
          }
          return DateTime(year, month, day, hour, minute);
        }
      }
    }

    // Pattern: "Day Month Year" (e.g. "15 Cze 2026" or "15. Cze 2026")
    final dmyMatch = RegExp(
      r'^(\d{1,2})(?:\.|\s+)\s*([a-zA-ZąćęłńóśźżĄĆĘŁŃÓŚŹŻ]+)(?:,|\.)?\s+(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final monthStr = dmyMatch.group(2)!.toLowerCase();
      final month = _monthMap[monthStr];
      final year = int.tryParse(dmyMatch.group(3)!);

      if (month != null && day != null && year != null) {
        if (day >= 1 && day <= 31 && year >= 1900 && year <= 2200) {
          var hour = 0;
          var minute = 0;
          if (dmyMatch.group(4) != null && dmyMatch.group(5) != null) {
            hour = int.parse(dmyMatch.group(4)!);
            minute = int.parse(dmyMatch.group(5)!);
            final amPm = dmyMatch.group(7)?.toLowerCase();
            if (amPm == 'pm' && hour < 12) hour += 12;
            if (amPm == 'am' && hour == 12) hour = 0;
          }
          return DateTime(year, month, day, hour, minute);
        }
      }
    }

    return null;
  }

  /// Finds column indices for date, time, weight, and note in the header fields.
  static Map<String, int?> _findColumnIndices(List<String> header) {
    final indices = <String, int?>{};
    for (int i = 0; i < header.length; i++) {
      final normalized = header[i].toLowerCase().trim();
      if (normalized == 'data' ||
          normalized == 'date' ||
          normalized == 'data_date' ||
          normalized == 'datetime' ||
          normalized == 'timestamp') {
        indices['data'] = i;
      } else if (normalized == 'czas' || normalized == 'time') {
        indices['czas'] = i;
      } else if (normalized == 'waga' ||
          normalized == 'waga (kg)' ||
          normalized == 'waga_kg' ||
          normalized == 'ciężar' ||
          normalized == 'ciezar' ||
          normalized == 'weight' ||
          normalized == 'weight (kg)' ||
          normalized == 'weight_kg' ||
          normalized == 'body mass' ||
          normalized == 'body_mass' ||
          normalized == 'body mass (kg)') {
        indices['waga'] = i;
      } else if (normalized == 'notatka' ||
          normalized == 'notatki' ||
          normalized == 'komentarz' ||
          normalized == 'note' ||
          normalized == 'notes' ||
          normalized == 'komentarz_note' ||
          normalized == 'memo') {
        indices['komentarz'] = i;
      }
    }

    if (indices['data'] == null && indices['czas'] != null) {
      indices['data'] = indices['czas'];
    }
    return indices;
  }

  /// Splits a single CSV line into fields, honoring RFC 4180 double-quoting.
  static List<String> _parseCsvLine(String line, String delimiter) {
    final fields = <String>[];
    final current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
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
