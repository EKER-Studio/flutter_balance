import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';

/// Initializes and provides the [Isar] database instance.
///
/// ## Schema Versioning & Recovery
/// Isar Community 3.x uses automatic schema migration for non-breaking additions
/// (e.g. indices or new optional fields). For breaking schema changes:
/// 1. Increment database version name suffix (e.g. `pure_weight_v2`).
/// 2. If initialization fails due to schema corruption or file lock issues,
///    [initialize] captures the failure, creates a timestamped backup of the
///    corrupted database, cleans up stale locks, and safely re-opens a fresh instance.
class DatabaseModule {
  /// The versioned database name. Increment suffix on breaking schema changes.
  ///
  /// Bumped v1 -> v2 when [WeightEntryModel] moved from plaintext
  /// `weightKg`/`note` fields to `encryptedWeight`/`encryptedNote`. This is a
  /// breaking rename, not an additive change, so per the policy above it
  /// requires a new database file rather than reopening v1 under the new
  /// schema (which would silently read empty ciphertext for every historical
  /// entry and decrypt it as 0.0 kg — see [_quarantineLegacyDatabase]).
  static const String dbName = 'pure_weight_v2';

  /// Name of the pre-encryption database, kept only so any existing v1 file
  /// can be quarantined instead of being left as a silently-orphaned file.
  static const String _legacyDbName = 'pure_weight_v1';

  static const String _encryptionKeyKey = 'isar_encryption_key';

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  /// Retrieves or generates a 256-bit AES encryption key from secure storage.
  static Future<Uint8List> getEncryptionKey() async {
    final stored = await _secureStorage.read(key: _encryptionKeyKey);
    if (stored != null) {
      return Uint8List.fromList(base64Decode(stored));
    }
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _secureStorage.write(
      key: _encryptionKeyKey,
      value: base64Encode(key),
    );
    return key;
  }

  /// Opens and returns an [Isar] instance with all registered schemas.
  ///
  /// Features:
  /// - Field-Level Encryption key managed via platform secure storage
  /// - Automatic compactOnLaunch when file exceeds threshold
  /// - Instance reuse check for hot reload / re-init safety
  /// - Graceful fallback & automatic DB backup/reset on schema corruption
  ///
  /// ```dart
  /// final isar = await DatabaseModule.initialize();
  /// ```
  static Future<Isar> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    // Reuse open instance if present (e.g. during re-init or hot restart)
    final existingInstance = Isar.getInstance(dbName);
    if (existingInstance != null && existingInstance.isOpen) {
      return existingInstance;
    }

    // Ensure 256-bit AES key is generated and persisted in secure storage.
    await getEncryptionKey();

    // One-time migration guard: move any pre-encryption v1 file out of the
    // way so it can never be opened under the v2 (encrypted) schema.
    await _quarantineLegacyDatabase(dir.path);

    try {
      return await _openIsar(dir.path);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[DatabaseModule] Failed to open Isar database: $e\n$stack');
      }
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] Attempting database backup and safe recovery reset...',
        );
      }

      try {
        await backupCorruptedDatabase(dir.path);
      } catch (backupError) {
        if (kDebugMode) {
          debugPrint('[DatabaseModule] Database backup failed: $backupError');
        }
      }

      // Re-attempt opening freshly initialized database after recovery cleanup
      try {
        return await _openIsar(dir.path);
      } catch (retryError, retryStack) {
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Recovery re-opening failed: $retryError\n$retryStack',
          );
        }
        rethrow;
      }
    }
  }

  /// Verifies database integrity upon application resumption from background state.
  ///
  /// Checks if the active Isar instance handle is open and valid. If closed or evicted
  /// by OS low-memory termination while backgrounded, attempts a clean auto-reconnect.
  /// Returns the live instance together with a `reopened` flag indicating whether
  /// a fresh instance had to be opened (in which case existing Isar query streams
  /// are dead and consumers should re-subscribe).
  static Future<({Isar instance, bool reopened})>
  ensureInstanceIntegrity() async {
    try {
      final instance = Isar.getInstance(dbName);
      if (instance == null || !instance.isOpen) {
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Isar instance invalid or closed on app resumption. Re-initializing...',
          );
        }
        return (instance: await initialize(), reopened: true);
      }
      return (instance: instance, reopened: false);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] Error verifying Isar instance integrity on resumption: $e\n$stack',
        );
      }
      return (instance: await initialize(), reopened: true);
    }
  }

  /// Opens the Isar instance for [directoryPath] with automatic compaction
  /// and the v2 encrypted schema registered.
  static Future<Isar> _openIsar(String directoryPath) {
    return Isar.open(
      [WeightEntryModelSchema],
      directory: directoryPath,
      name: dbName,
      compactOnLaunch: const CompactCondition(
        minFileSize: 10 * 1024 * 1024, // 10 MB
        minRatio: 1.25,
      ),
    );
  }

  /// Moves a pre-encryption `pure_weight_v1.isar` file (if present) to a
  /// `.legacy_unencrypted.bak` file so it is never opened under the v2
  /// (encrypted) schema.
  ///
  /// This is a safety guard, not a data migration: values inside the legacy
  /// file remain in plaintext and are NOT copied into the new v2 database.
  /// It only prevents the silent-corruption failure mode where Isar reopens
  /// the old file under the new schema and every historical entry decrypts
  /// to `0.0 kg` (see [dbName] doc comment). Runs at most once — if the
  /// legacy file is already gone (already quarantined, or a fresh install),
  /// this is a no-op.
  @visibleForTesting
  static Future<void> quarantineLegacyDatabaseForTesting(
    String directoryPath,
  ) => _quarantineLegacyDatabase(directoryPath);

  static Future<void> _quarantineLegacyDatabase(String directoryPath) async {
    final legacyFile = File('$directoryPath/$_legacyDbName.isar');
    if (!await legacyFile.exists()) {
      return;
    }
    final quarantinePath =
        '$directoryPath/$_legacyDbName.legacy_unencrypted.bak';
    try {
      await legacyFile.rename(quarantinePath);
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] Quarantined pre-encryption database to '
          '$quarantinePath (data not auto-migrated into v2).',
        );
      }
    } catch (e, stack) {
      // rename() can fail across filesystems/volumes; fall back to copy+delete.
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] rename() failed for legacy db, falling back to '
          'copy+delete: $e\n$stack',
        );
      }
      try {
        await legacyFile.copy(quarantinePath);
        await legacyFile.delete();
      } catch (fallbackError, fallbackStack) {
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Failed to quarantine legacy database: '
            '$fallbackError\n$fallbackStack',
          );
        }
      }
    }
  }

  /// Backs up corrupted or incompatible database files to a timestamped backup file
  /// and removes the old database file to allow clean recovery.
  @visibleForTesting
  static Future<void> backupCorruptedDatabase(String directoryPath) async {
    final dbFile = File('$directoryPath/$dbName.isar');
    final lockFile = File('$directoryPath/$dbName.isar.lock');

    if (await dbFile.exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath =
          '$directoryPath/${dbName}_corrupted_$timestamp.isar.bak';
      await dbFile.copy(backupPath);
      await dbFile.delete();
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] Corrupted database backed up to $backupPath',
        );
      }
    }

    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  }
}
