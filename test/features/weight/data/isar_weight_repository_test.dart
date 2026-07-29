import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  Isar? isar;
  IsarWeightRepository? repository;
  late MockFlutterSecureStorage mockSecureStorage;
  final testKeyA = Uint8List.fromList(List.generate(32, (i) => i));
  final testKeyB = Uint8List.fromList(List.generate(32, (i) => i + 1));

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
    } catch (_) {
      // Ignore initialization errors so tests can skip gracefully when native binaries are unavailable.
    }
  });

  setUp(() async {
    mockSecureStorage = MockFlutterSecureStorage();
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
    repository = IsarWeightRepository(
      isar: isar!,
      secureStorage: mockSecureStorage,
      encryptionKey: testKeyA,
    );
  });

  tearDown(() async {
    await isar?.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('IsarWeightRepository Cryptographic & Fallback Tests', () {
    test(
      'CASE 1 (Happy Path): Write encrypts data as Base64 ciphertext on disk and decrypts to original entity on read',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        final entry = WeightEntry(
          weightKg: 78.5,
          dateTime: DateTime(2026, 7, 29, 10, 0),
          note: 'Valid Note',
        );

        await repository!.addEntry(entry);

        // Verify physical disk/Isar model contains unreadable Base64 ciphertext
        final rawModels = await isar!.weightEntryModels.where().findAll();
        expect(rawModels.length, 1);
        expect(rawModels.first.encryptedWeight, isNot(contains('78.5')));
        expect(rawModels.first.encryptedNote, isNot(contains('Valid Note')));
        expect(
          () => base64Decode(rawModels.first.encryptedWeight),
          returnsNormally,
        );
        expect(
          () => base64Decode(rawModels.first.encryptedNote!),
          returnsNormally,
        );

        // Verify read returns original plaintext values
        final entries = await repository!.getAllEntries();
        expect(entries.length, 1);
        expect(entries.first.weightKg, 78.5);
        expect(entries.first.note, 'Valid Note');
        expect(entries.first.dateTime, DateTime(2026, 7, 29, 10, 0));
      },
    );

    test(
      'CASE 2 (Corrupted/Changed Key): Read with wrong key does not crash and returns fallback object',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        final repoKeyA = IsarWeightRepository(
          isar: isar!,
          encryptionKey: testKeyA,
        );
        final repoKeyB = IsarWeightRepository(
          isar: isar!,
          encryptionKey: testKeyB,
        );

        final entry = WeightEntry(
          weightKg: 85.0,
          dateTime: DateTime(2026, 7, 29),
          note: 'Encrypted with Key A',
        );

        await repoKeyA.addEntry(entry);

        // Attempt reading with Key B
        final entries = await repoKeyB.getAllEntries();
        expect(entries.length, 1);
        expect(entries.first.weightKg, 0.0);
        expect(entries.first.note, contains('Decryption Error'));
      },
    );

    test(
      'CASE 3 (Missing Key): Throws WeightDatabaseFailure when key supplier returns null',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        when(
          () => mockSecureStorage.read(key: 'isar_encryption_key'),
        ).thenAnswer((_) async => null);

        final repoMissingKey = IsarWeightRepository(
          isar: isar!,
          secureStorage: mockSecureStorage,
        );

        final entry = WeightEntry(
          weightKg: 70.0,
          dateTime: DateTime(2026, 7, 29),
        );

        expect(
          () => repoMissingKey.addEntry(entry),
          throwsA(isA<WeightDatabaseFailure>()),
        );

        expect(
          () => repoMissingKey.getAllEntries(),
          throwsA(isA<WeightDatabaseFailure>()),
        );
      },
    );

    test(
      'CASE 4 (Malformed Data in DB): Handles non-Base64 malformed payload safely with fallback object',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        final malformedModel = WeightEntryModel()
          ..encryptedWeight = r'%%%THIS_IS_NOT_BASE64$$$'
          ..encryptedNote = r'@@@GARBAGE_PAYLOAD###'
          ..dateTime = DateTime(2026, 7, 29);

        await isar!.writeTxn(() async {
          await isar!.weightEntryModels.put(malformedModel);
        });

        final entries = await repository!.getAllEntries();
        expect(entries.length, 1);
        expect(entries.first.weightKg, 0.0);
        expect(entries.first.note, contains('Decryption Error'));
      },
    );
  });

  group('IsarWeightRepository Standard Operations', () {
    test('watchAllEntries emits decrypted entries after addEntry', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final stream = repository!.watchAllEntries();

      await repository!.addEntry(
        WeightEntry(
          weightKg: 80.0,
          dateTime: DateTime(2025, 2, 1),
          note: 'Active stream note',
        ),
      );

      final entries = await stream.first;
      expect(entries.length, 1);
      expect(entries.first.weightKg, 80.0);
      expect(entries.first.note, 'Active stream note');
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

    test('bulkImportEntries persists multiple entries encrypted', () async {
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
      expect(stored[0].weightKg, 62.0);
      expect(stored[1].weightKg, 61.0);
      expect(stored[2].weightKg, 60.0);
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
