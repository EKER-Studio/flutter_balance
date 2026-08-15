import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:balance/core/database/database_module.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';

/// A test double that points [getApplicationDocumentsDirectory] at a
/// temporary directory so [DatabaseModule.initialize] runs fully on disk.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.fileSystemPath);

  /// The path returned as the application documents directory.
  final String fileSystemPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => fileSystemPath;

  @override
  Future<String?> getApplicationSupportPath() async => fileSystemPath;

  @override
  Future<String?> getTemporaryPath() async => fileSystemPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseModule', () {
    test('dbName is versioned correctly', () {
      expect(DatabaseModule.dbName, 'balance_v1');
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

  group('DatabaseModule getEncryptionKey', () {
    const secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(secureStorageChannel, null);
    });

    test('returns the previously stored key from secure storage', () async {
      final storedKey = List<int>.generate(32, (i) => i);
      final log = <MethodCall>[];
      messenger.setMockMethodCallHandler(secureStorageChannel, (
        MethodCall call,
      ) async {
        log.add(call);
        if (call.method == 'read') return base64Encode(storedKey);
        return null;
      });

      final key = await DatabaseModule.getEncryptionKey();

      expect(key, Uint8List.fromList(storedKey));
      final readCall = log.firstWhere((c) => c.method == 'read');
      expect(readCall.arguments['key'], 'isar_encryption_key');
    });

    test('generates a fresh 256-bit key and persists it', () async {
      final log = <MethodCall>[];
      messenger.setMockMethodCallHandler(secureStorageChannel, (
        MethodCall call,
      ) async {
        log.add(call);
        return null;
      });

      final key = await DatabaseModule.getEncryptionKey();

      expect(key.length, 32);
      final writeCall = log.firstWhere((c) => c.method == 'write');
      expect(writeCall.arguments['key'], 'isar_encryption_key');
      expect(base64Decode(writeCall.arguments['value'] as String), key);
    });
  });

  group('DatabaseModule initialize', () {
    late Directory tempDir;
    late PathProviderPlatform originalPathProvider;
    final openedInstances = <Isar>[];
    const secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('isar_init_');
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
      final leftover = Isar.getInstance(DatabaseModule.dbName);
      if (leftover != null && leftover.isOpen) {
        await leftover.close();
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
    });

    tearDown(() async {
      for (final instance in openedInstances) {
        if (instance.isOpen) {
          await instance.close();
        }
      }
      openedInstances.clear();
      PathProviderPlatform.instance = originalPathProvider;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns the existing open instance instead of reopening', () async {
      final existing = await Isar.open(
        [WeightEntryModelSchema],
        directory: tempDir.path,
        name: DatabaseModule.dbName,
      );
      openedInstances.add(existing);

      final result = await DatabaseModule.initialize();

      expect(identical(result, existing), isTrue);
    });

    test('opens a fresh instance and persists an encryption key', () async {
      final isar = await DatabaseModule.initialize();
      openedInstances.add(isar);

      expect(isar.isOpen, isTrue);
      expect(identical(Isar.getInstance(DatabaseModule.dbName), isar), isTrue);
      final dbFile = File('${tempDir.path}/${DatabaseModule.dbName}.isar');
      expect(dbFile.existsSync(), isTrue);
    });

    test('rethrows when the database cannot be recovered', () async {
      final dbFile = File('${tempDir.path}/${DatabaseModule.dbName}.isar');
      dbFile.writeAsBytesSync(List.filled(4096, 7));
      final chmodDir = await Process.run('chmod', ['0555', tempDir.path]);
      final chmodFile = await Process.run('chmod', ['0444', dbFile.path]);
      if (chmodDir.exitCode != 0 || chmodFile.exitCode != 0) {
        markTestSkipped('chmod not supported in this environment');
        await Process.run('chmod', ['0755', tempDir.path]);
        return;
      }
      try {
        await expectLater(DatabaseModule.initialize(), throwsA(isA<Object>()));
      } finally {
        await Process.run('chmod', ['0755', tempDir.path]);
        await Process.run('chmod', ['0644', dbFile.path]);
      }
    });
  });

  group('DatabaseModule quarantineLegacyDatabaseForTesting', () {
    test('is a no-op when no legacy database names are registered', () async {
      final tempDir = Directory.systemTemp.createTempSync('isar_legacy_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      await DatabaseModule.quarantineLegacyDatabaseForTesting(tempDir.path);

      expect(tempDir.listSync(), isEmpty);
    });
  });

  group('DatabaseModule ensureInstanceIntegrity', () {
    late Directory tempDir;
    late PathProviderPlatform originalPathProvider;
    final openedInstances = <Isar>[];
    const secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('isar_integrity_');
      originalPathProvider = PathProviderPlatform.instance;
      final leftover = Isar.getInstance(DatabaseModule.dbName);
      if (leftover != null && leftover.isOpen) {
        await leftover.close();
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
    });

    tearDown(() async {
      for (final instance in openedInstances) {
        if (instance.isOpen) {
          await instance.close();
        }
      }
      openedInstances.clear();
      PathProviderPlatform.instance = originalPathProvider;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns the live instance with reopened=false', () async {
      final existing = await Isar.open(
        [WeightEntryModelSchema],
        directory: tempDir.path,
        name: DatabaseModule.dbName,
      );
      openedInstances.add(existing);

      final result = await DatabaseModule.ensureInstanceIntegrity();

      expect(result.reopened, isFalse);
      expect(identical(result.instance, existing), isTrue);
    });

    test(
      're-initializes with reopened=true when no instance is open',
      () async {
        PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
        final instanceToClose = Isar.getInstance(DatabaseModule.dbName);
        if (instanceToClose != null && instanceToClose.isOpen) {
          await instanceToClose.close();
        }

        final result = await DatabaseModule.ensureInstanceIntegrity();
        openedInstances.add(result.instance);

        expect(result.reopened, isTrue);
        expect(result.instance.isOpen, isTrue);
        expect(
          identical(Isar.getInstance(DatabaseModule.dbName), result.instance),
          isTrue,
        );
      },
    );

    test('rethrows when the recovery initialization itself fails', () async {
      PathProviderPlatform.instance = FakePathProviderPlatform(
        '${tempDir.path}/does_not_exist',
      );
      final instanceToClose = Isar.getInstance(DatabaseModule.dbName);
      if (instanceToClose != null && instanceToClose.isOpen) {
        await instanceToClose.close();
      }

      await expectLater(
        DatabaseModule.ensureInstanceIntegrity(),
        throwsA(isA<Object>()),
      );
    });
  });
}
