import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/csv_exporter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return '.';
          },
        );
  });

  group('CsvExporter', () {
    test('generateCsv formats entries correctly', () {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 70.5,
          dateTime: DateTime(2026, 7, 24, 15, 0),
          note: 'After lunch',
        ),
        WeightEntry(
          id: 2,
          weightKg: 69.0,
          dateTime: DateTime(2026, 7, 25, 8, 30),
        ),
      ];

      final csv = CsvExporter.generateCsv(entries);
      final rows = csv.split('\n');

      expect(rows.length, greaterThanOrEqualTo(3));
      expect(rows[0], 'ID,Date,Weight (kg),Note');
      expect(rows[1], '1,2026-07-24 15:00,70.5,After lunch');
      expect(rows[2], '2,2026-07-25 08:30,69.0,');
    });

    test('generateCsv handles empty entries list', () {
      final csv = CsvExporter.generateCsv([]);
      final rows = csv.split('\n');

      expect(rows.length, 1);
      expect(rows[0], 'ID,Date,Weight (kg),Note');
    });

    test('exportToFile writes CSV content to disk file', () async {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 75.0,
          dateTime: DateTime(2026, 8, 1, 8, 0),
          note: 'Test export file',
        ),
      ];

      final file = await CsvExporter.exportToFile(entries);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('ID,Date,Weight (kg),Note'));
      expect(content, contains('1,2026-08-01 08:00,75.0,Test export file'));

      // Cleanup
      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
