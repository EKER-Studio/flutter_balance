import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/core/utils/field_cipher.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';

/// Isar-backed implementation of [WeightRepository] using Field-Level AES-256 Encryption.
class IsarWeightRepository implements WeightRepository {
  /// Default cap on entries loaded/watched at once, newest-first.
  ///
  /// Covers roughly 14 years of daily weigh-ins plus multiple measurements
  /// per day, so the cap is practically unreachable for realistic users.
  static const int defaultMaxEntriesLoaded = 5000;

  /// Maximum number of entries loaded/watched at once, newest-first.
  ///
  /// Bounds memory/UI cost for very long-running users. Entries beyond this
  /// cap are not visible to [WeightBloc] (streaks, statistics, calendar).
  /// Configurable for tests; add pagination rather than raising this further.
  final int maxEntriesLoaded;

  /// The Isar database instance.
  final Isar isar;

  /// Secure storage instance for retrieving the encryption key.
  final FlutterSecureStorage secureStorage;

  /// Cached AES-256 encryption key.
  Uint8List? _encryptionKey;

  /// Creates a repository backed by [isar] and managed secure storage.
  ///
  /// Takes an optional [secureStorage] handler.
  /// Takes an optional [encryptionKey] for testing override.
  /// Takes an optional [maxEntriesLoaded] cap, defaulting to [defaultMaxEntriesLoaded].
  IsarWeightRepository({
    required this.isar,
    this.secureStorage = const FlutterSecureStorage(),
    this._encryptionKey,
    this.maxEntriesLoaded = defaultMaxEntriesLoaded,
  });

  /// Resolves the live Isar instance for this repository.
  ///
  /// Prefers the currently registered open instance with the same name so
  /// operations keep working after [DatabaseModule] recovers the database
  /// (e.g. on app resumption), falling back to the captured [isar] instance.
  Isar get liveIsar {
    final registered = Isar.getInstance(isar.name);
    return (registered != null && registered.isOpen) ? registered : isar;
  }

  Future<Uint8List> _getOrLoadKey({bool isWrite = false}) async {
    if (_encryptionKey != null) {
      return _encryptionKey!;
    }
    String? stored;
    try {
      stored = await secureStorage.read(key: 'isar_encryption_key');
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] Error reading key from secureStorage: $e\n$stack',
        );
      }
    }

    if (stored != null && stored.isNotEmpty) {
      final key = Uint8List.fromList(base64Decode(stored));
      _encryptionKey = key;
      return key;
    }

    throw WeightRepositoryException(
      type: isWrite ? WeightErrorType.writeFailed : WeightErrorType.readFailed,
      message: 'Missing or inaccessible encryption key',
    );
  }

  WeightEntry _modelToEntity(WeightEntryModel model, Uint8List key) {
    double weight = 0.0;
    String? note;

    try {
      final decryptedStr = FieldCipher.decrypt(model.encryptedWeight, key);
      weight = double.tryParse(decryptedStr) ?? 0.0;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] Decryption failed for weight (id: ${model.id}): $e\n$stack',
        );
      }
      weight = 0.0;
    }

    if (model.encryptedNote != null && model.encryptedNote!.isNotEmpty) {
      try {
        note = FieldCipher.decrypt(model.encryptedNote!, key);
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint(
            '[IsarWeightRepository] Decryption failed for note (id: ${model.id}): $e\n$stack',
          );
        }
        note = '[Decryption Error]';
      }
    }

    return WeightEntry(
      id: model.id,
      weightKg: weight,
      dateTime: model.dateTime,
      note: note,
    );
  }

  WeightEntryModel _entityToModel(WeightEntry entity, Uint8List key) {
    final model = WeightEntryModel()
      ..id = entity.id == 0 ? Isar.autoIncrement : entity.id
      ..dateTime = entity.dateTime
      ..encryptedWeight = FieldCipher.encrypt(entity.weightKg.toString(), key);

    if (entity.note != null && entity.note!.isNotEmpty) {
      model.encryptedNote = FieldCipher.encrypt(entity.note!, key);
    } else {
      model.encryptedNote = null;
    }

    return model;
  }

  @override
  Stream<List<WeightEntry>> watchAllEntries() {
    return liveIsar.weightEntryModels
        .where()
        .sortByDateTimeDesc()
        .limit(maxEntriesLoaded)
        .watch(fireImmediately: true)
        .asyncMap((models) async {
          try {
            final key = await _getOrLoadKey(isWrite: false);
            return models.map((m) => _modelToEntity(m, key)).toList();
          } on WeightRepositoryException {
            rethrow;
          } catch (e, stack) {
            if (kDebugMode) {
              debugPrint(
                '[IsarWeightRepository] watchAllEntries decryption error: '
                '$e\n$stack',
              );
            }
            throw WeightRepositoryException(
              type: WeightErrorType.readFailed,
              message: 'Failed to decrypt weight entries: $e',
              sourceError: e,
            );
          }
        })
        .handleError(
          (Object error, StackTrace stack) {
            if (kDebugMode) {
              debugPrint(
                '[IsarWeightRepository] watchAllEntries source stream error: '
                '$error\n$stack',
              );
            }
            // Rethrow as a domain exception so the BLoC receives typed errors
            // instead of raw infrastructure exceptions. The stream continues
            // emitting after this error (cancelOnError is false in the BLoC).
            // ignore: only_throw_errors
            throw WeightRepositoryException(
              type: WeightErrorType.streamError,
              message: 'Weight entry stream infrastructure failure: $error',
              sourceError: error,
            );
          },
          test: (error) => error is! WeightRepositoryException,
        );
  }

  @override
  Future<List<WeightEntry>> getAllEntries() async {
    try {
      final key = await _getOrLoadKey(isWrite: false);
      final models = await liveIsar.weightEntryModels
          .where()
          .sortByDateTimeDesc()
          .limit(maxEntriesLoaded)
          .findAll();
      return models.map((m) => _modelToEntity(m, key)).toList();
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] getAllEntries IsarError: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'Database read failure: ${e.message}',
        sourceError: e,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] getAllEntries unexpected error: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'Unexpected error while reading entries: $e',
        sourceError: e,
      );
    }
  }

  @override
  Future<void> addEntry(WeightEntry entry) async {
    try {
      final key = await _getOrLoadKey(isWrite: true);
      final model = _entityToModel(entry, key);
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.put(model);
      });
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[IsarWeightRepository] addEntry IsarError: $e\n$stack');
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Database write failure: ${e.message}',
        sourceError: e,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] addEntry unexpected error: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Unexpected error while adding entry: $e',
        sourceError: e,
      );
    }
  }

  @override
  Future<void> deleteEntry(int id) async {
    try {
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.delete(id);
      });
    } on IsarError catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[IsarWeightRepository] deleteEntry IsarError: $e\n$stack');
      }
      throw WeightRepositoryException(
        type: WeightErrorType.deleteEntryFailed,
        message: 'Database delete failure: ${e.message}',
        sourceError: e,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] deleteEntry unexpected error: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.deleteEntryFailed,
        message: 'Unexpected error while deleting entry: $e',
        sourceError: e,
      );
    }
  }

  @override
  Future<int> bulkImportEntries(List<WeightEntry> entries) async {
    try {
      final key = await _getOrLoadKey(isWrite: true);
      final models = entries.map((e) => _entityToModel(e, key)).toList();
      await liveIsar.writeTxn(() async {
        await liveIsar.weightEntryModels.putAll(models);
      });
      return models.length;
    } on WeightRepositoryException {
      rethrow;
    } on IsarError catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] bulkImportEntries IsarError: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Database bulk import failure: ${e.message}',
        sourceError: e,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] bulkImportEntries unexpected error: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Unexpected error during bulk import: $e',
        sourceError: e,
      );
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      await liveIsar.writeTxn(() async {
        await liveIsar.clear();
      });
    } on IsarError catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[IsarWeightRepository] clearAllData IsarError: $e\n$stack');
      }
      throw WeightRepositoryException(
        type: WeightErrorType.wipeFailed,
        message: 'Database wipe failure: ${e.message}',
        sourceError: e,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[IsarWeightRepository] clearAllData unexpected error: $e\n$stack',
        );
      }
      throw WeightRepositoryException(
        type: WeightErrorType.wipeFailed,
        message: 'Unexpected error while clearing data: $e',
        sourceError: e,
      );
    }
  }
}
