import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';

void main() {
  group('CsvErrorType', () {
    test('contains all expected failure modes', () {
      expect(CsvErrorType.values, [
        CsvErrorType.fileTooLarge,
        CsvErrorType.invalidFormat,
        CsvErrorType.noEntries,
      ]);
    });

    test('has three distinct values', () {
      expect(CsvErrorType.values.length, 3);
      expect(CsvErrorType.values.toSet().length, 3);
    });

    test('values are distinct and comparable', () {
      expect(CsvErrorType.fileTooLarge, isNot(CsvErrorType.invalidFormat));
      expect(CsvErrorType.invalidFormat, isNot(CsvErrorType.noEntries));
      expect(CsvErrorType.fileTooLarge, isNot(CsvErrorType.noEntries));
    });
  });
}
