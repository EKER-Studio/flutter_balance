import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Domain repository interface for managing persistent weight entries.
///
/// Serves as the abstraction boundary between domain logic and persistence implementations.
/// Provides methods for querying, watching real-time changes, adding, deleting, and bulk-importing [WeightEntry] entities.
abstract class WeightRepository {
  /// Watches all persisted weight records as a real-time reactive stream.
  ///
  /// Emits a new [List] of [WeightEntry] objects immediately upon subscription and
  /// whenever any entry is created, modified, or deleted in the underlying data store.
  Stream<List<WeightEntry>> watchAllEntries();

  /// Fetches all stored weight entries as a static single-shot list.
  ///
  /// Returns a [Future] that resolves to a [List] containing all [WeightEntry] entities.
  Future<List<WeightEntry>> getAllEntries();

  /// Persists a new or updated [entry] into the storage system.
  ///
  /// Returns a [Future] that completes when [entry] is successfully saved.
  Future<void> addEntry(WeightEntry entry);

  /// Removes the weight entry associated with the given [id].
  ///
  /// Returns a [Future] that completes when the entry corresponding to [id] is deleted.
  Future<void> deleteEntry(int id);

  /// Bulk imports a collection of [entries] within a single transactional operation.
  ///
  /// Updates existing entries matching primary keys and inserts new entries.
  /// Returns a [Future] completing with the total number of [WeightEntry] items imported.
  Future<int> bulkImportEntries(List<WeightEntry> entries);
}
