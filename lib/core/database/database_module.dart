import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/features/weight/data/models/weight_entry_model.dart';

/// Manages database initialization, AES encryption key provisioning, and crash-recovery.
///
/// ## Schema Versioning & Recovery
/// Isar Community 3.x uses automatic schema migration for non-breaking additions
/// (e.g. indices or new optional fields). For breaking schema changes:
/// 1. Increment the database version name suffix (e.g. `balance_v2`).
/// 2. If initialization fails due to schema corruption or file lock issues,
///    [initialize] captures the failure, creates a timestamped backup of the
///    corrupted database, cleans up stale locks, and safely re-opens a fresh instance.
class DatabaseModule {
  /// The versioned database name.
  ///
  /// Increment the suffix on breaking schema changes.
  ///
  /// The name changed from `pure_weight_v2` to `balance_v1` during the
  /// PureWeight -> Balance rebrand (2026-08). The old `pure_weight_v2` file is
  /// not reopened: it holds data from the previous app identity, so it is
  /// quarantined on first launch instead (see [_quarantineLegacyDatabase]).
  static const String dbName = 'balance_v1';

  /// The names of databases from previous app versions.
  ///
  /// These are kept only so any existing files can be quarantined instead of
  /// being left as silently-orphaned files.
  static const List<String> _legacyDbNames = [];

  static const String _encryptionKeyKey = 'isar_encryption_key';
  static const String _encryptionKeyFileName = 'balance_v1.key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Retrieves or generates a 256-bit AES encryption key.
  ///
  /// Checks for a persisted key file in the application documents directory
  /// (which is included in Android Cloud Backup). If not present, falls back
  /// to [FlutterSecureStorage] to migrate existing keys, and writes the key to
  /// the file. If neither exists, generates a fresh random 256-bit key and
  /// stores it in both places.
  ///
  /// @param directoryPath Optional directory override (used in testing).
  static Future<Uint8List> getEncryptionKey([String? directoryPath]) async {
    File? keyFile;
    try {
      final dirPath =
          directoryPath ?? (await getApplicationDocumentsDirectory()).path;
      keyFile = File('$dirPath/$_encryptionKeyFileName');

      if (await keyFile.exists()) {
        final content = (await keyFile.readAsString()).trim();
        if (content.isNotEmpty) {
          final decoded = base64Decode(content);
          if (decoded.length == 32) {
            return Uint8List.fromList(decoded);
          }
        }
      }
    } catch (_) {
      // Path provider may be unavailable in some isolated test environments
    }

    // Fallback/Migration: Check FlutterSecureStorage
    String? stored;
    try {
      stored = await _secureStorage.read(key: _encryptionKeyKey);
    } catch (_) {
      // Secure storage might fail or be unavailable
    }

    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = base64Decode(stored);
        if (decoded.length == 32) {
          try {
            await keyFile?.writeAsString(stored);
          } catch (_) {}
          return Uint8List.fromList(decoded);
        }
      } catch (e) {
        throw FormatException('Malformed stored encryption key: $e');
      }
    }

    // Generate fresh key
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    final base64Key = base64Encode(key);

    try {
      await keyFile?.writeAsString(base64Key);
    } catch (_) {}

    try {
      await _secureStorage.write(key: _encryptionKeyKey, value: base64Key);
    } catch (_) {}

    return key;
  }

  /// Opens and returns an Isar instance with all registered schemas.
  ///
  /// Features:
  /// - Field-Level Encryption key managed via platform secure storage
  /// - Automatic compactOnLaunch when file exceeds threshold
  /// - Instance reuse check for hot reload / re-init safety
  /// - Graceful fallback & automatic DB backup/reset on schema corruption
  static Future<Isar> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    // Reuse open instance if present (e.g. during re-init or hot restart)
    final existingInstance = Isar.getInstance(dbName);
    if (existingInstance != null && existingInstance.isOpen) {
      return existingInstance;
    }

    // Ensure 256-bit AES key is generated and persisted in secure storage.
    await getEncryptionKey();

    // One-time migration guard: move any legacy database file out of the
    // way so it can never be opened under the current schema.
    await _quarantineLegacyDatabase(dir.path);

    try {
      return await _openIsar(dir.path);
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[DatabaseModule] Failed to open Isar database',
        fatal: false,
      );

      try {
        await backupCorruptedDatabase(dir.path);
      } catch (backupError, backupStack) {
        AppCrashReporter.recordError(
          backupError,
          backupStack,
          reason: '[DatabaseModule] Database backup during recovery failed',
          fatal: false,
        );
      }

      // Re-attempt opening the freshly initialized database after recovery cleanup.
      try {
        return await _openIsar(dir.path);
      } catch (retryError, retryStack) {
        AppCrashReporter.recordError(
          retryError,
          retryStack,
          reason: '[DatabaseModule] Recovery re-opening failed',
          fatal: true,
        );
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
      AppCrashReporter.recordError(
        e,
        stack,
        reason:
            '[DatabaseModule] Error verifying Isar instance integrity on resumption',
        fatal: false,
      );
      return (instance: await initialize(), reopened: true);
    }
  }

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

  /// Moves database files from previous app versions to timestamped `.legacy.bak` backup files.
  ///
  /// Legacy files are moved so they are never opened under the current schema.
  /// This is a safety guard, not a data migration: values inside the legacy
  /// files are NOT copied into the new `balance_v1` database. It prevents the
  /// silent-corruption failure mode where Isar reopens an old file under a new
  /// schema and historical entries decrypt to `0.0 kg` (see
  /// [DatabaseModule.dbName] doc comment). Runs at most once — if a legacy
  /// file is already gone (already quarantined, or a fresh install), it is a no-op.
  @visibleForTesting
  static Future<void> quarantineLegacyDatabaseForTesting(
    String directoryPath,
  ) => _quarantineLegacyDatabase(directoryPath);

  static Future<void> _quarantineLegacyDatabase(String directoryPath) async {
    for (final legacyName in _legacyDbNames) {
      final legacyFile = File('$directoryPath/$legacyName.isar');
      if (!await legacyFile.exists()) {
        continue;
      }
      final quarantinePath = '$directoryPath/$legacyName.legacy.bak';
      try {
        await legacyFile.rename(quarantinePath);
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Quarantined legacy database to $quarantinePath '
            '(data not auto-migrated into $dbName).',
          );
        }
      } catch (e) {
        // rename() can fail across filesystems/volumes; fall back to copy+delete.
        try {
          await legacyFile.copy(quarantinePath);
          await legacyFile.delete();
        } catch (fallbackError, fallbackStack) {
          AppCrashReporter.recordError(
            fallbackError,
            fallbackStack,
            reason: '[DatabaseModule] Failed to quarantine legacy database',
            fatal: false,
          );
        }
      }
    }
  }

  /// Creates a point-in-time snapshot backup of the current database before risky
  /// bulk operations (e.g. CSV import).
  ///
  /// Backs up to `balance_v1_pre_import.isar.bak`. If the database file does not
  /// exist yet (e.g. fresh installation), this is a safe no-op.
  static Future<String?> createPreImportSnapshot([
    String? directoryPath,
  ]) async {
    try {
      final path =
          directoryPath ?? (await getApplicationDocumentsDirectory()).path;
      final dbFile = File('$path/$dbName.isar');
      if (await dbFile.exists()) {
        final backupPath = '$path/${dbName}_pre_import.isar.bak';
        await dbFile.copy(backupPath);
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Pre-import snapshot created at $backupPath',
          );
        }
        return backupPath;
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[DatabaseModule] Failed to create pre-import snapshot',
        fatal: false,
      );
    }
    return null;
  }

  /// Backs up corrupted or incompatible database files to a timestamped backup file.
  ///
  /// Removes the old database file to allow clean recovery.
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
