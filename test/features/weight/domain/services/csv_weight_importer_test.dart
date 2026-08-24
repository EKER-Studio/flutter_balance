import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/services/csv_weight_importer.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWeightRepository mockRepository;
  late CsvWeightImporter importer;
  late Directory tempDir;

  setUp(() async {
    mockRepository = MockWeightRepository();
    importer = CsvWeightImporter(repository: mockRepository);
    tempDir = await Directory.systemTemp.createTemp('csv_importer_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CsvWeightImporter', () {
    test(
      'analyzeFile returns CsvAnalysisSuccess for valid CSV content',
      () async {
        final file = File('${tempDir.path}/valid.csv');
        await file.writeAsString(
          'Date,Weight\n2026-08-24 08:00,75.5\n2026-08-23 08:00,76.0',
        );

        final result = await importer.analyzeFile(file.path);

        expect(result, isA<CsvAnalysisSuccess>());
        final success = result as CsvAnalysisSuccess;
        expect(success.analysis.validEntries.length, 2);
      },
    );

    test(
      'analyzeFile returns CsvAnalysisFailure with noEntries when file is empty',
      () async {
        final file = File('${tempDir.path}/empty.csv');
        await file.writeAsString('Date,Weight\n');

        final result = await importer.analyzeFile(file.path);

        expect(result, isA<CsvAnalysisFailure>());
        final failure = result as CsvAnalysisFailure;
        expect(failure.errorType, CsvErrorType.noEntries);
      },
    );

    test('confirmImport invokes repository.bulkImportEntries', () async {
      final entries = [
        WeightEntry(weightKg: 75.0, dateTime: DateTime(2026, 8, 24)),
      ];
      when(
        () => mockRepository.bulkImportEntries(entries),
      ).thenAnswer((_) async => 1);

      final count = await importer.confirmImport(entries);

      expect(count, 1);
      verify(() => mockRepository.bulkImportEntries(entries)).called(1);
    });
  });
}
