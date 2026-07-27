import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/utils/csv_exporter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

void main() {
  test('CsvExporter.generateCsv formats entries correctly', () {
    final entries = [
      WeightEntry(
        id: 1,
        weightKg: 70.5,
        bmi: 22.5,
        dateTime: DateTime(2026, 7, 24, 15, 0),
        note: 'After lunch',
      ),
      WeightEntry(
        id: 2,
        weightKg: 69.0,
        bmi: 22.0,
        dateTime: DateTime(2026, 7, 25, 8, 30),
      ),
    ];

    final csv = CsvExporter.generateCsv(entries);
    final rows = csv.split('\n');

    expect(rows.length, greaterThanOrEqualTo(3));
    expect(rows[0], 'ID,Data,Waga (kg),BMI,Notatka');
    expect(rows[1], '1,2026-07-24 15:00,70.5,22.5,After lunch');
    expect(rows[2], '2,2026-07-25 08:30,69.0,22.0,');
  });
}
