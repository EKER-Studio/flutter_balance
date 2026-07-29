import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static const String dbName = 'pure_weight_v1';

  /// Opens and returns an [Isar] instance with all registered schemas.
  ///
  /// Features:
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
  static Future<Isar?> ensureInstanceIntegrity() async {
    try {
      final instance = Isar.getInstance(dbName);
      if (instance == null || !instance.isOpen) {
        if (kDebugMode) {
          debugPrint(
            '[DatabaseModule] Isar instance invalid or closed on app resumption. Re-initializing...',
          );
        }
        return await initialize();
      }
      return instance;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[DatabaseModule] Error verifying Isar instance integrity on resumption: $e\n$stack',
        );
      }
      return await initialize();
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
