import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Domain repository contract for managing persistent weight entries.
///
/// Serves as the Clean Architecture abstraction boundary between domain logic
/// and concrete persistence data handlers (e.g. Isar database).
abstract class WeightRepository {
  /// Watches all persisted weight records as a real-time reactive stream.
  ///
  /// Emits a new [List] of [WeightEntry] objects immediately upon subscription and
  /// whenever any entry is created, modified, or deleted in the underlying data store.
  /// May emit a stream error if underlying database stream connection fails.
  Stream<List<WeightEntry>> watchAllEntries();

  /// Fetches all stored weight entries as a static single-shot list.
  ///
  /// Returns a [Future] resolving to a [List] of all persisted [WeightEntry] entities.
  /// May throw a database error if local storage is unreadable.
  Future<List<WeightEntry>> getAllEntries();

  /// Persists a new or updated [entry] into the storage system.
  ///
  /// Takes a mandatory [WeightEntry] entity to save.
  /// Returns a [Future] that completes when [entry] is successfully saved.
  /// May throw a database error if disk space is full or transaction fails.
  Future<void> addEntry(WeightEntry entry);

  /// Removes the weight entry associated with the given [id].
  ///
  /// Takes an integer [id] identifying the target record.
  /// Returns a [Future] that completes when the entry corresponding to [id] is deleted.
  /// May throw a database error if record deletion fails.
  Future<void> deleteEntry(int id);

  /// Bulk imports a collection of [entries] within a single transactional operation.
  ///
  /// Takes a list of [WeightEntry] items to import in batch.
  /// Returns a [Future] completing with the total integer count of items imported.
  /// May throw a database error if transaction fails.
  Future<int> bulkImportEntries(List<WeightEntry> entries);

  /// Removes all stored weight data from persistent storage.
  ///
  /// Returns a [Future] that completes when all collections are wiped.
  /// May throw a database error if collection transaction fails.
  Future<void> clearAllData();
}
