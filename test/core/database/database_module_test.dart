import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';

void main() {
  group('DatabaseModule', () {
    test('dbName is versioned correctly', () {
      expect(DatabaseModule.dbName, 'pure_weight_v1');
    });

    test('getInstance returns null when instance is uninitialized', () {
      final instance = Isar.getInstance(DatabaseModule.dbName);
      expect(instance, isNull);
    });

    group('backupCorruptedDatabase', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('isar_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test(
        'creates timestamped .bak file and removes original db file',
        () async {
          final dbPath = '${tempDir.path}/${DatabaseModule.dbName}.isar';
          File(dbPath).writeAsBytesSync([0, 1, 2, 3, 4]);

          await DatabaseModule.backupCorruptedDatabase(tempDir.path);

          final remainingFiles = tempDir.listSync().map((e) => e.path).toList();
          final bakFiles = remainingFiles
              .where((p) => p.endsWith('.isar.bak'))
              .toList();

          expect(bakFiles.length, 1);
          expect(bakFiles.first, contains('corrupted'));
          expect(File(dbPath).existsSync(), isFalse);
        },
      );

      test('removes stale lock file during recovery', () async {
        final lockPath = '${tempDir.path}/${DatabaseModule.dbName}.isar.lock';
        File(lockPath).writeAsBytesSync([]);

        await DatabaseModule.backupCorruptedDatabase(tempDir.path);

        expect(File(lockPath).existsSync(), isFalse);
      });

      test('succeeds silently when no database file exists', () async {
        await DatabaseModule.backupCorruptedDatabase(tempDir.path);

        final files = tempDir.listSync();
        expect(files, isEmpty);
      });

      test('backs up only the db file and preserves unrelated files', () async {
        final dbPath = '${tempDir.path}/${DatabaseModule.dbName}.isar';
        File(dbPath).writeAsBytesSync([0, 1, 2]);
        final otherPath = '${tempDir.path}/other_file.txt';
        File(otherPath).writeAsBytesSync([99]);

        await DatabaseModule.backupCorruptedDatabase(tempDir.path);

        expect(File(otherPath).existsSync(), isTrue);
        expect(File(dbPath).existsSync(), isFalse);
        expect(
          tempDir.listSync().where((e) => e.path.endsWith('.bak')),
          hasLength(1),
        );
      });
    });
  });

  group('DatabaseModule Integration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('isar_integration_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'create record, watch broadcast, physical write check, reopen',
      () async {
        try {
          final testDb = await Isar.open(
            [WeightEntryModelSchema],
            directory: tempDir.path,
            name: 'test_integration_db',
          );
          await testDb.close();
        } catch (_) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }

        final dbName = 'test_integration_db';

        final isar = await Isar.open(
          [WeightEntryModelSchema],
          directory: tempDir.path,
          name: dbName,
        );

        final model = WeightEntryModel()
          ..encryptedWeight = 'test_encrypted_payload'
          ..dateTime = DateTime(2026, 7, 29, 8, 0);
        await isar.writeTxn(() async {
          await isar.weightEntryModels.put(model);
        });

        final entriesFromWatch = await isar.weightEntryModels
            .where()
            .watch(fireImmediately: true)
            .first;
        expect(entriesFromWatch.length, 1);
        expect(
          entriesFromWatch.first.encryptedWeight,
          'test_encrypted_payload',
        );

        final dbFilePath = '${tempDir.path}/$dbName.isar';
        expect(File(dbFilePath).existsSync(), isTrue);
        final fileSize = File(dbFilePath).lengthSync();
        expect(fileSize, greaterThan(0));

        await isar.close();

        final reopenedIsar = await Isar.open(
          [WeightEntryModelSchema],
          directory: tempDir.path,
          name: dbName,
        );

        final persistedEntries = await reopenedIsar.weightEntryModels
            .where()
            .findAll();
        expect(persistedEntries.length, 1);
        expect(
          persistedEntries.first.encryptedWeight,
          'test_encrypted_payload',
        );

        await reopenedIsar.close();
      },
    );
  });
}
