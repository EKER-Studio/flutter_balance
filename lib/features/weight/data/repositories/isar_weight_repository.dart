import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';

/// Isar-backed implementation of [WeightRepository].
class IsarWeightRepository implements WeightRepository {
  /// The Isar database instance.
  final Isar isar;

  /// Creates a repository backed by the given [isar] instance.
  IsarWeightRepository({required this.isar});

  @override
  Stream<List<WeightEntry>> watchAllEntries() {
    return isar.weightEntryModels
        .where()
        .sortByDateTimeDesc()
        .limit(500)
        .watch(fireImmediately: true)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<WeightEntry>> getAllEntries() async {
    try {
      final models = await isar.weightEntryModels
          .where()
          .sortByDateTimeDesc()
          .limit(500)
          .findAll();
      return models.map((m) => m.toEntity()).toList();
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
      final model = WeightEntryModel.fromEntity(entry);
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
      final models = entries.map(WeightEntryModel.fromEntity).toList();
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
