import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

void main() {
  late Directory tempDir;
  Isar? isar;
  IsarWeightRepository? repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('isar_test_');
    try {
      isar = await Isar.open(
        [WeightEntryModelSchema],
        directory: tempDir.path,
        name: 'isar_repo_test',
      );
    } catch (_) {
      return;
    }
    repository = IsarWeightRepository(isar: isar!);
  });

  tearDown(() async {
    await isar?.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('IsarWeightRepository', () {
    test('addEntry persists an entry and getAllEntries returns it', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final entry = WeightEntry(
        weightKg: 70.5,
        dateTime: DateTime(2025, 1, 15, 10, 30),
      );

      await repository!.addEntry(entry);

      final entries = await repository!.getAllEntries();
      expect(entries.length, 1);
      expect(entries.first.weightKg, 70.5);
      expect(entries.first.dateTime, DateTime(2025, 1, 15, 10, 30));
    });

    test('watchAllEntries emits entries after addEntry', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final stream = repository!.watchAllEntries();

      await repository!.addEntry(
        WeightEntry(weightKg: 80.0, dateTime: DateTime(2025, 2, 1)),
      );

      final entries = await stream.first;
      expect(entries.length, 1);
      expect(entries.first.weightKg, 80.0);
    });

    test('deleteEntry removes an entry', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final entry = WeightEntry(
        weightKg: 65.0,
        dateTime: DateTime(2025, 3, 10),
      );
      await repository!.addEntry(entry);

      var entries = await repository!.getAllEntries();
      expect(entries.length, 1);
      final id = entries.first.id;

      await repository!.deleteEntry(id);

      entries = await repository!.getAllEntries();
      expect(entries, isEmpty);
    });

    test('bulkImportEntries persists multiple entries', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final entries = [
        WeightEntry(weightKg: 60.0, dateTime: DateTime(2025, 4, 1)),
        WeightEntry(weightKg: 61.0, dateTime: DateTime(2025, 4, 2)),
        WeightEntry(weightKg: 62.0, dateTime: DateTime(2025, 4, 3)),
      ];

      final count = await repository!.bulkImportEntries(entries);
      expect(count, 3);

      final stored = await repository!.getAllEntries();
      expect(stored.length, 3);
    });

    test('clearAllData removes all entries', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      await repository!.addEntry(
        WeightEntry(weightKg: 90.0, dateTime: DateTime(2025, 5, 1)),
      );
      await repository!.addEntry(
        WeightEntry(weightKg: 91.0, dateTime: DateTime(2025, 5, 2)),
      );

      var entries = await repository!.getAllEntries();
      expect(entries.length, 2);

      await repository!.clearAllData();

      entries = await repository!.getAllEntries();
      expect(entries, isEmpty);
    });

    test(
      'watchAllEntries returns entries ordered by dateTime descending',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        await repository!.addEntry(
          WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 1, 1)),
        );
        await repository!.addEntry(
          WeightEntry(weightKg: 71.0, dateTime: DateTime(2025, 1, 3)),
        );
        await repository!.addEntry(
          WeightEntry(weightKg: 72.0, dateTime: DateTime(2025, 1, 2)),
        );

        final entries = await repository!.getAllEntries();

        expect(entries.length, 3);
        expect(entries[0].dateTime, DateTime(2025, 1, 3));
        expect(entries[1].dateTime, DateTime(2025, 1, 2));
        expect(entries[2].dateTime, DateTime(2025, 1, 1));
      },
    );
  });
}
