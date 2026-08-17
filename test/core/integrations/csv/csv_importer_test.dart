import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/core/integrations/csv/csv_exporter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('CsvImporter.parse', () {
    test('parses valid CSV with comma delimiter and Polish headers', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15,75.2,23.1,
2,2024-01-16,75.0,23.0,Notowanie poranne
3,2024-01-17,74.8,22.9,
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 3);
      expect(result.skippedRowCount, 0);
      expect(entries[0].weightKg, 75.2);
      expect(entries[0].dateTime, DateTime(2024, 1, 15));
      expect(entries[0].note, '');

      expect(entries[1].weightKg, 75.0);
      expect(entries[1].dateTime, DateTime(2024, 1, 16));
      expect(entries[1].note, 'Notowanie poranne');

      expect(entries[2].weightKg, 74.8);
      expect(entries[2].dateTime, DateTime(2024, 1, 17));
      expect(entries[2].note, '');
    });

    test(
      'parses valid CSV with semicolon delimiter and English headers',
      () async {
        const csvContent = '''
ID;Date;Weight;BMI;Note
1;2024-02-01;80.5;24.0;
2;2024-02-02;80.0;23.8;Evening weigh-in
''';

        final result = await CsvImporter.parse(csvContent);
        final entries = result.validEntries;

        expect(entries.length, 2);
        expect(result.skippedRowCount, 0);
        expect(entries[0].weightKg, 80.5);
        expect(entries[0].dateTime, DateTime(2024, 2, 1));

        expect(entries[1].weightKg, 80.0);
        expect(entries[1].dateTime, DateTime(2024, 2, 2));
        expect(entries[1].note, 'Evening weigh-in');
      },
    );

    test('parses CSV without optional note column', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI
1,2024-03-01,70.0,22.0
2,2024-03-02,70.5,22.1
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].weightKg, 70.0);
      expect(entries[0].note, null);
      expect(entries[1].weightKg, 70.5);
      expect(entries[1].note, null);
    });

    test('skips malformed rows gracefully', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15,75.2,23.1,
2,not-a-date,75.0,23.0,Bad date
3,2024-01-17,abc,22.9,Bad weight
4,2024-01-18,74.8,22.8,Valid entry
5,2024-01-19,-5.0,22.7,Negative weight
6,2024-01-20,600.0,22.8,Unrealistic weight
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 4);
      expect(entries[0].dateTime, DateTime(2024, 1, 15));
      expect(entries[0].weightKg, 75.2);
      expect(entries[1].dateTime, DateTime(2024, 1, 18));
      expect(entries[1].weightKg, 74.8);
      expect(entries[1].note, 'Valid entry');
    });

    test('throws FormatException for empty CSV content', () {
      expect(() => CsvImporter.parse(''), throwsFormatException);
    });

    test('throws FormatException for CSV with no header', () {
      const csvContent = '''
2024-01-15,75.2,
2024-01-16,75.0,
''';

      expect(() => CsvImporter.parse(csvContent), throwsFormatException);
    });

    test('throws FormatException for CSV with missing required columns', () {
      const csvContent = '''
ID,Wiek,Waga (kg)
1,30,75.0
2,31,76.0
''';

      expect(
        () => CsvImporter.parse(csvContent),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles quoted fields with commas inside', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15,75.2,23.1,"Notatka z przecinkiem"
2,2024-01-16,75.0,23.0,"Waga ""poranna"" 7:00"
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].note, 'Notatka z przecinkiem');
      expect(entries[1].note, 'Waga "poranna" 7:00');
    });

    test('handles CSV with Windows-style line endings', () async {
      const csvContent =
          'ID,Data,Waga (kg),BMI,Notatka\r\n1,2024-01-15,75.2,23.1,\r\n2,2024-01-16,75.0,23.0,Test\r\n';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].weightKg, 75.2);
      expect(entries[1].weightKg, 75.0);
      expect(entries[1].note, 'Test');
    });

    test('handles CSV with extra whitespace in fields', () async {
      const csvContent = '''
  ID  ,  Data  ,  Waga (kg)  ,  BMI  ,  Notatka  
  1  ,  2024-01-15  ,  75.2  ,  23.1  ,  Trimmed note  
  2  ,  2024-01-16  ,  75.0  ,  23.0  ,  
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].weightKg, 75.2);
      expect(entries[0].note, 'Trimmed note');
      expect(entries[1].weightKg, 75.0);
      expect(entries[1].note, '');
    });

    test('parses CSV with time component in date', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15 07:30,75.2,23.1,
2,2024-01-16T19:45:00,75.0,23.0,
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].dateTime.hour, 7);
      expect(entries[0].dateTime.minute, 30);
      expect(entries[1].dateTime.hour, 19);
      expect(entries[1].dateTime.minute, 45);
    });

    test('handles CSV with only header row (no data)', () async {
      const csvContent = 'ID,Data,Waga (kg),BMI,Notatka';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries, isEmpty);
      expect(result.skippedRowCount, 0);
    });

    test('parses CSV with weight at boundary values', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15,20,23.1,Minimum weight
2,2024-01-16,300,23.0,Maximum weight
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].weightKg, 20);
      expect(entries[1].weightKg, 300);
    });

    test('skips rows outside the valid weight range', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
1,2024-01-15,0.1,23.1,Below range
2,2024-01-16,300.1,23.0,Above range
3,2024-01-17,75,23.1,Valid
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 1);
      expect(result.skippedRowCount, 2);
      expect(entries[0].weightKg, 75);
    });

    test('parses CSV with ID column not used', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
999,2024-01-15,75.2,23.1,
1000,2024-01-16,75.0,23.0,
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      // ID is not stored in WeightEntry (it's auto-assigned)
      expect(entries[0].weightKg, 75.2);
      expect(entries[1].weightKg, 75.0);
    });

    test('parses European date format dd.MM.yyyy', () async {
      const csvContent = '''
Data,Waga
15.01.2024,75.2
03.02.2024,80.0
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].dateTime, DateTime(2024, 1, 15));
      expect(entries[0].weightKg, 75.2);
      expect(entries[1].dateTime, DateTime(2024, 2, 3));
      expect(entries[1].weightKg, 80.0);
    });

    test('parses European date format dd/MM/yyyy', () async {
      const csvContent = '''
Date,Weight
15/01/2024,75.2
03/02/2024,80.0
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].dateTime, DateTime(2024, 1, 15));
      expect(entries[0].weightKg, 75.2);
      expect(entries[1].dateTime, DateTime(2024, 2, 3));
      expect(entries[1].weightKg, 80.0);
    });

    test(
      'parses European weight format with comma as decimal separator',
      () async {
        // European CSV uses semicolons when comma is the decimal separator
        const csvContent = '''
Data;Waga
2024-01-15;75,2
2024-01-16;80,0
''';

        final result = await CsvImporter.parse(csvContent);
        final entries = result.validEntries;

        expect(entries.length, 2);
        expect(result.skippedRowCount, 0);
        expect(entries[0].weightKg, 75.2);
        expect(entries[1].weightKg, 80.0);
      },
    );

    test('flawless export -> re-import roundtrip', () async {
      final originalEntries = [
        WeightEntry(
          id: 1,
          weightKg: 72.4,
          dateTime: DateTime(2026, 8, 10, 12, 34),
          note: 'Roundtrip test 1',
        ),
        WeightEntry(
          id: 2,
          weightKg: 71.9,
          dateTime: DateTime(2026, 8, 11, 7, 15),
          note: 'Roundtrip test 2',
        ),
      ];

      // Export
      final csvContent = CsvExporter.generateCsv(originalEntries);

      // Import
      final result = await CsvImporter.parse(csvContent);
      final importedEntries = result.validEntries;

      expect(importedEntries.length, 2);
      expect(result.skippedRowCount, 0);

      expect(importedEntries[0].weightKg, 72.4);
      expect(importedEntries[0].dateTime, DateTime(2026, 8, 10, 12, 34));
      expect(importedEntries[0].note, 'Roundtrip test 1');

      expect(importedEntries[1].weightKg, 71.9);
      expect(importedEntries[1].dateTime, DateTime(2026, 8, 11, 7, 15));
      expect(importedEntries[1].note, 'Roundtrip test 2');
    });
    test('parses a time column and combines it with the date', () async {
      const csvContent = '''
ID,Data,Czas,Waga,BMI,Notatka
1,2024-01-15,07:30,75.2,23.1,
2,2024-01-16,19:45,75.0,23.0,Evening
''';

      final result = await CsvImporter.parse(csvContent);

      expect(result.validEntries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(result.validEntries[0].dateTime, DateTime(2024, 1, 15, 7, 30));
      expect(result.validEntries[1].dateTime, DateTime(2024, 1, 16, 19, 45));
    });

    test('keeps the parsed date when the time column is malformed', () async {
      const csvContent = '''
ID,Date,Time,Weight,Note
1,2024-01-15,not-a-time,75.2,Keeps date
2,2024-01-16,9,75.0,Single part
''';

      final result = await CsvImporter.parse(csvContent);

      expect(result.validEntries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(result.validEntries[0].dateTime, DateTime(2024, 1, 15));
      expect(result.validEntries[1].dateTime, DateTime(2024, 1, 16));
    });

    test('skips data rows with fewer than two fields', () async {
      const csvContent = '''
ID,Data,Waga (kg),BMI,Notatka
2024-01-15
garbage
2,2024-01-16,75.0,23.0,Valid
''';

      final result = await CsvImporter.parse(csvContent);

      expect(result.validEntries.length, 1);
      expect(result.skippedRowCount, 2);
      expect(result.validEntries[0].weightKg, 75.0);
    });

    test(
      'parses Garmin Connect Polish hierarchical CSV export with metadata line',
      () async {
        const csvContent = '''
weight
Czas,Ciężar,Zmiana,BMI,Tkanka tłuszczowa,Masa mięśni szkieletowych,Masa kostna,Woda w organizmie
Cze 15, 2026,,,,,,,
9:26 AM,88.6 kg,0.6 kg,28.3,--,--,--,--
Cze 14, 2026,,,,,,,
8:34 AM,88.0 kg,0.5 kg,28.1,--,--,--,--
''';

        final result = await CsvImporter.parse(csvContent);
        final entries = result.validEntries;

        expect(entries.length, 2);
        expect(result.skippedRowCount, 0);

        expect(entries[0].dateTime, DateTime(2026, 6, 15, 9, 26));
        expect(entries[0].weightKg, 88.6);

        expect(entries[1].dateTime, DateTime(2026, 6, 14, 8, 34));
        expect(entries[1].weightKg, 88.0);
      },
    );

    test(
      'parses Zepp Life / Garmin export with 24-hour and PM times and Polish months',
      () async {
        const csvContent = '''
Czas,Waga,Notatka
15 Paź 2025 14:30,78,5 kg,Popołudniowy
16 Lis 2025 1:48 PM,79.1 kg,Po treningu
''';

        final result = await CsvImporter.parse(csvContent);
        final entries = result.validEntries;

        expect(entries.length, 2);
        expect(result.skippedRowCount, 0);

        expect(entries[0].dateTime, DateTime(2025, 10, 15, 14, 30));
        expect(entries[0].weightKg, 78.5);
        expect(entries[0].note, 'Popołudniowy');

        expect(entries[1].dateTime, DateTime(2025, 11, 16, 13, 48));
        expect(entries[1].weightKg, 79.1);
        expect(entries[1].note, 'Po treningu');
      },
    );

    test('parses CSV with body mass header and lbs/g sanitization', () async {
      const csvContent = '''
Timestamp,Body Mass,Memo
2026-05-10 08:00,82.4 kg,Morning
2026-05-11 08:00,82.1,No unit
''';

      final result = await CsvImporter.parse(csvContent);
      final entries = result.validEntries;

      expect(entries.length, 2);
      expect(result.skippedRowCount, 0);
      expect(entries[0].dateTime, DateTime(2026, 5, 10, 8, 0));
      expect(entries[0].weightKg, 82.4);
      expect(entries[0].note, 'Morning');
      expect(entries[1].dateTime, DateTime(2026, 5, 11, 8, 0));
      expect(entries[1].weightKg, 82.1);
      expect(entries[1].note, 'No unit');
    });

    test(
      'parses multiple measurements per hierarchical date group with corrupted rows',
      () async {
        const csvContent = '''
Activities export
Data,Ciężar
Cze 15, 2026,
12:00 AM,85.0 kg
12:00 PM,85.5 kg
bad-time,86.0 kg
9:30 PM,invalid-weight
Cze 16, 2026,
07:15,84.8
''';

        final result = await CsvImporter.parse(csvContent);
        final entries = result.validEntries;

        expect(entries.length, 3);
        expect(result.skippedRowCount, 2);

        expect(entries[0].dateTime, DateTime(2026, 6, 15, 0, 0));
        expect(entries[0].weightKg, 85.0);

        expect(entries[1].dateTime, DateTime(2026, 6, 15, 12, 0));
        expect(entries[1].weightKg, 85.5);

        expect(entries[2].dateTime, DateTime(2026, 6, 16, 7, 15));
        expect(entries[2].weightKg, 84.8);
      },
    );
  });
}
