import 'package:isar_community/isar.dart';
import 'package:pure_weight/features/weight/data/models/weight_entry_model.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';

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
        .watch(fireImmediately: true)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<List<WeightEntry>> getAllEntries() async {
    final models = await isar.weightEntryModels.where().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addEntry(WeightEntry entry) async {
    final model = WeightEntryModel.fromEntity(entry);
    await isar.writeTxn(() async {
      await isar.weightEntryModels.put(model);
    });
  }

  @override
  Future<void> deleteEntry(int id) async {
    await isar.writeTxn(() async {
      await isar.weightEntryModels.delete(id);
    });
  }

  @override
  Future<int> bulkImportEntries(List<WeightEntry> entries) async {
    final models = entries.map(WeightEntryModel.fromEntity).toList();
    await isar.writeTxn(() async {
      await isar.weightEntryModels.putAll(models);
    });
    return models.length;
  }

  /// Removes any stored BMI values by re-writing all entries without BMI.
  ///
  /// This reads all entries, clears the collection and re-inserts entries
  /// using the current model mapping (which no longer includes `bmi`).
  /// Use this as a one-time migration helper after schema changes that
  /// removed the `bmi` property.
  Future<void> removeStoredBmiFromDb() async {
    final entries = await getAllEntries();
    await isar.writeTxn(() async {
      await isar.weightEntryModels.where().deleteAll();
      for (final entry in entries) {
        final model = WeightEntryModel.fromEntity(entry);
        await isar.weightEntryModels.put(model);
      }
    });
  }
}
