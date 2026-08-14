import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/utils/field_cipher.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';
import 'package:balance/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Polls [predicate] until it returns true or [timeout] elapses.
Future<void> waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

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
        inspector: false,
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
      'CASE 1.5 (Full FieldCipher round-trip): On-disk ciphertext decrypts via FieldCipher and repository read matches the exact original inputs',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        final original = WeightEntry(
          weightKg: 87.25,
          dateTime: DateTime(2026, 7, 29, 23, 59, 30, 123),
          note: 'Stretki ąśćżźł — ünïcödé 🎯',
        );

        await repository!.addEntry(original);

        // The persisted model must hold ciphertext that FieldCipher decrypts
        // back to exactly the plaintext values handed to the repository.
        final rawModels = await isar!.weightEntryModels.where().findAll();
        expect(rawModels.length, 1);
        expect(
          FieldCipher.decrypt(rawModels.first.encryptedWeight, testKeyA),
          '87.25',
        );
        expect(
          FieldCipher.decrypt(rawModels.first.encryptedNote!, testKeyA),
          original.note,
        );

        // Reading via the repository must restore the original entries verbatim.
        final entries = await repository!.getAllEntries();
        expect(entries.length, 1);
        expect(entries.first.weightKg, original.weightKg);
        expect(entries.first.note, original.note);
        expect(entries.first.dateTime, original.dateTime);
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
      final entriesFuture = stream.firstWhere((e) => e.length == 1);

      await repository!.addEntry(
        WeightEntry(
          weightKg: 80.0,
          dateTime: DateTime(2025, 2, 1),
          note: 'Active stream note',
        ),
      );

      final entries = await entriesFuture;
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

  group('IsarWeightRepository Stream Resilience', () {
    test('watchAllEntries surfaces errors as domain exceptions and recovers '
        'after the unlock signal fires', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final unlockSignal = StreamController<void>.broadcast();
      final repo = IsarWeightRepository(
        isar: isar!,
        secureStorage: mockSecureStorage,
        unlockSignal: unlockSignal.stream,
      );
      when(
        () => mockSecureStorage.read(key: 'isar_encryption_key'),
      ).thenAnswer((_) async => null);

      // Persist an entry while the key is still available, so the watch phase
      // has encrypted data to decrypt once the keystore becomes accessible.
      final keyedWriter = IsarWeightRepository(
        isar: isar!,
        encryptionKey: testKeyA,
      );
      await keyedWriter.addEntry(
        WeightEntry(weightKg: 82.0, dateTime: DateTime(2025, 6, 1)),
      );

      final events = <Object>[];
      final streamDone = Completer<void>();
      final subscription = repo.watchAllEntries().listen(
        (entries) => events.add(entries),
        onError: (Object error, StackTrace stackTrace) => events.add(error),
        onDone: streamDone.complete,
      );
      addTearDown(subscription.cancel);
      addTearDown(unlockSignal.close);

      // First emission fails because the encryption key is inaccessible.
      await waitUntil(() => events.any((e) => e is WeightRepositoryException));

      // The key becomes available again; the unlock signal must trigger an
      // immediate re-subscribe instead of waiting out the backoff.
      when(
        () => mockSecureStorage.read(key: 'isar_encryption_key'),
      ).thenAnswer((_) async => base64Encode(testKeyA));
      unlockSignal.add(null);

      await waitUntil(() => events.any((e) => e is List<WeightEntry>));

      final recovered =
          events.firstWhere((e) => e is List<WeightEntry>) as List<WeightEntry>;
      expect(recovered.length, 1);
      expect(recovered.first.weightKg, 82.0);
      expect(streamDone.isCompleted, isFalse);
    });
  });

  group('IsarWeightRepository Failure Paths', () {
    test('secure storage read errors surface as domain exceptions', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      when(
        () => mockSecureStorage.read(key: 'isar_encryption_key'),
      ).thenThrow(PlatformException(code: 'keystore_locked'));

      final repo = IsarWeightRepository(
        isar: isar!,
        secureStorage: mockSecureStorage,
      );

      expect(
        () => repo.getAllEntries(),
        throwsA(
          isA<WeightDatabaseFailure>().having(
            (e) => e.type,
            'type',
            WeightErrorType.readFailed,
          ),
        ),
      );
      expect(
        () => repo.addEntry(
          WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 7, 1)),
        ),
        throwsA(
          isA<WeightDatabaseFailure>().having(
            (e) => e.type,
            'type',
            WeightErrorType.writeFailed,
          ),
        ),
      );
    });

    test(
      'corrupt stored key string maps to unexpected-error exceptions',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        when(
          () => mockSecureStorage.read(key: 'isar_encryption_key'),
        ).thenAnswer((_) async => 'not-valid-base64!!');

        final repo = IsarWeightRepository(
          isar: isar!,
          secureStorage: mockSecureStorage,
        );

        expect(
          () => repo.getAllEntries(),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.readFailed,
            ),
          ),
        );
        expect(
          () => repo.addEntry(
            WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 7, 1)),
          ),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.writeFailed,
            ),
          ),
        );
        expect(
          () => repo.bulkImportEntries([
            WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 7, 1)),
          ]),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.writeFailed,
            ),
          ),
        );
      },
    );

    test(
      'operations on a closed database map IsarError to domain exceptions',
      () async {
        if (isar == null) {
          markTestSkipped(
            'Isar native library not available in this environment',
          );
          return;
        }
        final closedDir = Directory.systemTemp.createTempSync('isar_closed_');
        addTearDown(() {
          if (closedDir.existsSync()) {
            closedDir.deleteSync(recursive: true);
          }
        });
        final closedIsar = await Isar.open(
          [WeightEntryModelSchema],
          directory: closedDir.path,
          name: 'isar_repo_fail_test',
          inspector: false,
        );
        await closedIsar.close();
        final repo = IsarWeightRepository(
          isar: closedIsar,
          encryptionKey: testKeyA,
        );

        expect(
          () => repo.getAllEntries(),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.readFailed,
            ),
          ),
        );
        expect(
          () => repo.addEntry(
            WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 7, 1)),
          ),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.writeFailed,
            ),
          ),
        );
        expect(
          () => repo.deleteEntry(1),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.deleteEntryFailed,
            ),
          ),
        );
        expect(
          () => repo.bulkImportEntries([
            WeightEntry(weightKg: 70.0, dateTime: DateTime(2025, 7, 1)),
          ]),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.writeFailed,
            ),
          ),
        );
        expect(
          () => repo.clearAllData(),
          throwsA(
            isA<WeightDatabaseFailure>().having(
              (e) => e.type,
              'type',
              WeightErrorType.wipeFailed,
            ),
          ),
        );
      },
    );

    test('bulkImportEntries encrypts and restores notes', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final entries = [
        WeightEntry(
          weightKg: 60.0,
          dateTime: DateTime(2025, 4, 1),
          note: 'First note',
        ),
        WeightEntry(weightKg: 61.0, dateTime: DateTime(2025, 4, 2)),
      ];

      final count = await repository!.bulkImportEntries(entries);
      expect(count, 2);

      final stored = await repository!.getAllEntries();
      expect(stored.first.note, isNull);
      expect(stored.last.note, 'First note');
    });

    test('watchAllEntries on a closed database throws synchronously', () async {
      if (isar == null) {
        markTestSkipped(
          'Isar native library not available in this environment',
        );
        return;
      }
      final closedDir = Directory.systemTemp.createTempSync(
        'isar_watch_closed_',
      );
      addTearDown(() {
        if (closedDir.existsSync()) {
          closedDir.deleteSync(recursive: true);
        }
      });
      final closedIsar = await Isar.open(
        [WeightEntryModelSchema],
        directory: closedDir.path,
        name: 'isar_repo_watch_fail_test',
        inspector: false,
      );
      await closedIsar.close();
      final repo = IsarWeightRepository(
        isar: closedIsar,
        encryptionKey: testKeyA,
      );

      expect(() => repo.watchAllEntries(), throwsA(isA<IsarError>()));
    });
  });

  group('resilientStream retry logic', () {
    test(
      'surfaces mapped errors and keeps retrying on repeated failures',
      () async {
        var attempts = 0;
        final stream = resilientStream<List<int>>(
          () {
            attempts++;
            return Stream.error(Exception('keystore locked'));
          },
          mapError: (error, stack) => StateError('mapped: $error'),
          backoffFor: (_) => const Duration(milliseconds: 10),
        );

        final errors = <Object>[];
        final subscription = stream.listen(
          (_) {},
          onError: (Object error, StackTrace stackTrace) => errors.add(error),
        );
        addTearDown(subscription.cancel);

        await waitUntil(() => errors.length >= 3);
        expect(attempts, greaterThanOrEqualTo(3));
        expect(errors.first, isA<StateError>());
      },
    );

    test('recovers once the source succeeds again', () async {
      var attempts = 0;
      final source = StreamController<List<int>>();
      final stream = resilientStream<List<int>>(
        () {
          attempts++;
          if (attempts == 1) {
            return Stream.error(Exception('keystore locked'));
          }
          return source.stream;
        },
        mapError: (error, stack) => StateError('mapped: $error'),
        backoffFor: (_) => const Duration(milliseconds: 10),
      );

      final events = <Object>[];
      final subscription = stream.listen(
        (entries) => events.add(entries),
        onError: (Object error, StackTrace stackTrace) => events.add(error),
      );
      addTearDown(subscription.cancel);
      addTearDown(source.close);

      await waitUntil(() => events.any((e) => e is StateError));
      source.add([1, 2, 3]);
      await waitUntil(() => events.whereType<List<int>>().isNotEmpty);
      expect(attempts, 2);
      final recovered = events.firstWhere((e) => e is List<int>);
      expect(recovered, [1, 2, 3]);
    });

    test('recovery signal skips the backoff wait', () async {
      final recoverySignal = StreamController<void>.broadcast();
      var attempts = 0;
      final stream = resilientStream<List<int>>(
        () {
          attempts++;
          if (attempts == 1) {
            return Stream.error(Exception('keystore locked'));
          }
          return Stream.value(const [7]);
        },
        mapError: (error, stack) => StateError('mapped: $error'),
        recoverySignal: recoverySignal.stream,
        backoffFor: (_) => const Duration(seconds: 30),
      );

      final events = <Object>[];
      final subscription = stream.listen(
        (entries) => events.add(entries),
        onError: (Object error, StackTrace stackTrace) => events.add(error),
      );
      addTearDown(subscription.cancel);
      addTearDown(recoverySignal.close);

      await waitUntil(() => events.any((e) => e is StateError));
      final started = DateTime.now();
      recoverySignal.add(null);
      await waitUntil(() => events.any((e) => e == const [7]));

      // Recovery happened well before the 30s backoff would have elapsed.
      expect(
        DateTime.now().difference(started),
        lessThan(const Duration(seconds: 5)),
      );
    });
  });
}
