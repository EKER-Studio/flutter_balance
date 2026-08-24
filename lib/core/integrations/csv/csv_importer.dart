import 'dart:isolate';
import 'dart:math' as math;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Result record returned by [CsvImporter.parse], carrying parsed entries and
/// audit statistics for the preview dialog and import confirmation flow.
typedef CsvImportAnalysis = ({
  List<WeightEntry> validEntries,
  int skippedRowCount,
  DateTime? earliestDate,
  DateTime? latestDate,
});

/// Parses weight-history CSV content into [WeightEntry] entities on a background isolate.
///
/// ## CSV contract
/// The parser mirrors the `CsvExporter` output and supports third-party exports
/// such as Garmin Connect and Zepp Life (including hierarchical date groups):
/// - Delimiter: auto-detected comma, semicolon, or tab.
/// - RFC 4180 quoted multi-line fields are supported via [CsvToListConverter].
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
/// - Anomaly filtering: rejects future timestamps (> now + 24 h), historic
///   outliers (< 2000-01-01), and notes longer than 500 characters are truncated.
class CsvImporter {
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
  /// UI thread. Returns a [CsvImportAnalysis] record carrying parsed
  /// [WeightEntry] entities, a skipped-row count, and the detected date range.
  ///
  /// Throws a [FormatException] when the content is empty or no valid header
  /// containing both date and weight columns is found.
  static Future<CsvImportAnalysis> parse(String csvContent) async {
    return Isolate.run(() => _parseSync(csvContent));
  }

  static CsvImportAnalysis _parseSync(String csvContent) {
    // Strip UTF-8 BOM if present.
    if (csvContent.startsWith('\uFEFF')) {
      csvContent = csvContent.substring(1);
    }

    // Normalize line endings for consistent CsvToListConverter behavior.
    final normalized = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    if (normalized.trim().isEmpty) {
      throw const FormatException('CSV content is empty');
    }

    // Step 1 — Detect delimiter and locate the header row.
    // Try each candidate delimiter with CsvToListConverter (RFC 4180-compliant)
    // so the header row is found correctly even when fields are quoted.
    int headerIdx = -1;
    String delimiter = ',';
    Map<String, int?> columnIndex = {};
    int headerColumnCount = 0;
    List<List<String>> rows = [];

    for (final delim in [',', ';', '\t']) {
      final parsed = Csv(
        fieldDelimiter: delim,
        lineDelimiter: '\n',
        dynamicTyping: false,
      ).decode(normalized);

      // Discard entirely-blank rows produced by trailing newlines.
      final nonEmpty = parsed
          .map((r) => r.map((e) => e.toString()).toList())
          .where((r) => r.any((f) => f.trim().isNotEmpty))
          .toList();

      for (int i = 0; i < nonEmpty.length; i++) {
        final fields = nonEmpty[i].map((f) => f.trim()).toList();
        final cols = _findColumnIndices(fields);
        if (cols['data'] != null && cols['waga'] != null) {
          headerIdx = i;
          delimiter = delim;
          columnIndex = cols;
          headerColumnCount = fields.length;
          rows = nonEmpty;
          break;
        }
      }
      if (headerIdx != -1) break;
    }

    if (headerIdx == -1) {
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
    DateTime? earliestDate;
    DateTime? latestDate;

    final futureLimit = DateTime.now().add(const Duration(hours: 24));
    final historicLimit = DateTime.utc(2000);

    // Step 2 — Iterate through data rows below the header.
    for (int i = headerIdx + 1; i < rows.length; i++) {
      var fields = rows[i].map((f) => f.trim()).toList();

      if (fields.length < 2) {
        skippedRows++;
        continue;
      }

      // Check for hierarchical date group rows (Garmin Connect format).
      // "Cze 15, 2026,,,,,,," is split by CsvToListConverter into
      // ['Cze 15', ' 2026', '', ...] when comma is the delimiter. Reconstruct
      // by joining the first n non-empty fields with ", ".
      bool isDateGroupRow = false;
      if (delimiter == ',') {
        for (int n = 2; n <= math.min(fields.length, 4); n++) {
          final candidate = fields
              .sublist(0, n)
              .where((f) => f.isNotEmpty)
              .join(', ');
          final parsed = _parseDate(candidate);
          if (parsed != null &&
              fields.sublist(n).every(_isPlaceholderOrEmpty)) {
            currentDateContext = parsed;
            isDateGroupRow = true;
            break;
          }
        }
      }
      if (isDateGroupRow) continue;

      final maxRequiredCol = math.max(dataCol, wagaCol);
      if (fields.length <= maxRequiredCol) {
        skippedRows++;
        continue;
      }

      final dateOrTimeRaw = fields[dataCol];
      final weightRawBeforeRepair = wagaCol < fields.length
          ? fields[wagaCol]
          : '';

      // Check if this row is a standard date group row (date in dataCol,
      // placeholder/empty in the weight column).
      final isPlaceholderWeight = _isPlaceholderOrEmpty(weightRawBeforeRepair);
      final parsedDirectDate = _parseDate(dateOrTimeRaw);

      if (parsedDirectDate != null && isPlaceholderWeight) {
        currentDateContext = parsedDirectDate;
        continue;
      }

      // Repair unquoted decimal comma in comma-delimited rows.
      // E.g. "...,78,5 kg,..." → merge into "78.5".
      if (delimiter == ',' &&
          wagaCol < fields.length - 1 &&
          fields.length > headerColumnCount) {
        final wagaPart1 = fields[wagaCol];
        final wagaPart2 = wagaCol + 1 < fields.length
            ? fields[wagaCol + 1]
            : '';
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

      // Parse and validate weight.
      final weightRaw = wagaCol < fields.length ? fields[wagaCol] : '';
      final weight = _cleanAndParseWeight(weightRaw);
      if (weight == null) {
        skippedRows++;
        continue;
      }

      // Resolve entry timestamp.
      DateTime? entryDateTime;

      // Case A: Separate time column present (e.g. ID,Date,Time,Weight,...).
      if (czasCol != null && czasCol != dataCol && fields.length > czasCol) {
        final timeRaw = fields[czasCol];
        var datePart = parsedDirectDate ?? _parseDate(dateOrTimeRaw);
        if (datePart == null && currentDateContext != null) {
          datePart = currentDateContext;
        }
        if (datePart != null) {
          final timePart = _parseTime(timeRaw);
          entryDateTime = timePart != null
              ? DateTime(
                  datePart.year,
                  datePart.month,
                  datePart.day,
                  timePart.hour,
                  timePart.minute,
                )
              : datePart;
        }
      }

      // Case B: Combined date/time in dataCol, or hierarchical time string.
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

      // Anomaly filters — reject physiologically implausible timestamps.
      if (entryDateTime.isAfter(futureLimit)) {
        skippedRows++;
        continue;
      }
      if (entryDateTime.toUtc().isBefore(historicLimit)) {
        skippedRows++;
        continue;
      }

      // Extract and sanitize note; truncate to 500 characters.
      final rawNote = (noteCol != null && noteCol < fields.length)
          ? fields[noteCol]
          : null;
      final note = rawNote != null && rawNote.length > 500
          ? rawNote.substring(0, 500)
          : rawNote;

      entries.add(
        WeightEntry(
          dateTime: entryDateTime,
          weightKg: weight,
          note: (note != null && note.isNotEmpty)
              ? note
              : (noteCol != null && noteCol < fields.length ? '' : null),
        ),
      );

      // Track date range across valid entries.
      if (earliestDate == null || entryDateTime.isBefore(earliestDate)) {
        earliestDate = entryDateTime;
      }
      if (latestDate == null || entryDateTime.isAfter(latestDate)) {
        latestDate = entryDateTime;
      }
    }

    return (
      validEntries: entries,
      skippedRowCount: skippedRows,
      earliestDate: earliestDate,
      latestDate: latestDate,
    );
  }

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

  static ({int hour, int minute})? _parseTime(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
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
      final monthStr = (mdyMatch.group(1) ?? '').toLowerCase();
      final month = _monthMap[monthStr];
      final day = int.tryParse(mdyMatch.group(2) ?? '');
      final year = int.tryParse(mdyMatch.group(3) ?? '');

      if (month != null && day != null && year != null) {
        if (day >= 1 && day <= 31 && year >= 1900 && year <= 2200) {
          var hour = 0;
          var minute = 0;
          if (mdyMatch.group(4) != null && mdyMatch.group(5) != null) {
            hour = int.tryParse(mdyMatch.group(4) ?? '') ?? 0;
            minute = int.tryParse(mdyMatch.group(5) ?? '') ?? 0;
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
      final day = int.tryParse(dmyMatch.group(1) ?? '');
      final monthStr = (dmyMatch.group(2) ?? '').toLowerCase();
      final month = _monthMap[monthStr];
      final year = int.tryParse(dmyMatch.group(3) ?? '');

      if (month != null && day != null && year != null) {
        if (day >= 1 && day <= 31 && year >= 1900 && year <= 2200) {
          var hour = 0;
          var minute = 0;
          if (dmyMatch.group(4) != null && dmyMatch.group(5) != null) {
            hour = int.tryParse(dmyMatch.group(4) ?? '') ?? 0;
            minute = int.tryParse(dmyMatch.group(5) ?? '') ?? 0;
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
}
