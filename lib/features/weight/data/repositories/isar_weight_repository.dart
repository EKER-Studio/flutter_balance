import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';

/// Isar-backed implementation of [WeightRepository] using Field-Level AES-256 Encryption.
class IsarWeightRepository implements WeightRepository {
  /// The Isar database instance.
  final Isar isar;

  /// Secure storage instance for retrieving the encryption key.
  final FlutterSecureStorage secureStorage;

  /// Cached AES-256 encryption key.
  Uint8List? _encryptionKey;

  /// Creates a repository backed by [isar] and managed secure storage.
  ///
  /// Takes an optional [secureStorage] handler.
  /// Takes an optional [_encryptionKey] for testing override.
  IsarWeightRepository({
    required this.isar,
    this.secureStorage = const FlutterSecureStorage(),
    Uint8List? encryptionKey,
  });

  Future<Uint8List> _getOrLoadKey() async {
    if (_encryptionKey != null) {
      return _encryptionKey!;
    }
    final key = await DatabaseModule.getEncryptionKey();
    _encryptionKey = key;
    return key;
  }

  String _encrypt(String plainText, Uint8List keyBytes) {
    final encKey = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  String _decrypt(String base64String, Uint8List keyBytes) {
    final combined = base64Decode(base64String);
    if (combined.length < 16) {
      throw const FormatException('Encrypted payload too short');
    }
    final ivBytes = combined.sublist(0, 16);
    final cipherBytes = combined.sublist(16);

    final encKey = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypted = enc.Encrypted(cipherBytes);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  WeightEntry _modelToEntity(WeightEntryModel model, Uint8List key) {
    double weight = 0.0;
    String? note;

    try {
      final decryptedStr = _decrypt(model.encryptedWeight, key);
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
        note = _decrypt(model.encryptedNote!, key);
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint(
            '[IsarWeightRepository] Decryption failed for note (id: ${model.id}): $e\n$stack',
          );
        }
        note = null;
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
      ..encryptedWeight = _encrypt(entity.weightKg.toString(), key);

    if (entity.note != null && entity.note!.isNotEmpty) {
      model.encryptedNote = _encrypt(entity.note!, key);
    } else {
      model.encryptedNote = null;
    }

    return model;
  }

  @override
  Stream<List<WeightEntry>> watchAllEntries() {
    return isar.weightEntryModels
        .where()
        .sortByDateTimeDesc()
        .limit(500)
        .watch(fireImmediately: true)
        .asyncMap((models) async {
          final key = await _getOrLoadKey();
          return models.map((m) => _modelToEntity(m, key)).toList();
        });
  }

  @override
  Future<List<WeightEntry>> getAllEntries() async {
    try {
      final key = await _getOrLoadKey();
      final models = await isar.weightEntryModels
          .where()
          .sortByDateTimeDesc()
          .limit(500)
          .findAll();
      return models.map((m) => _modelToEntity(m, key)).toList();
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
      final key = await _getOrLoadKey();
      final model = _entityToModel(entry, key);
      await isar.writeTxn(() async {
        await isar.weightEntryModels.put(model);
      });
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
      await isar.writeTxn(() async {
        await isar.weightEntryModels.delete(id);
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
      final key = await _getOrLoadKey();
      final models = entries.map((e) => _entityToModel(e, key)).toList();
      await isar.writeTxn(() async {
        await isar.weightEntryModels.putAll(models);
      });
      return models.length;
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
      await isar.writeTxn(() async {
        await isar.clear();
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
