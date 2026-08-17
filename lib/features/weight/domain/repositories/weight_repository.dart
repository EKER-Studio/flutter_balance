import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A domain repository contract for managing persistent weight entries.
///
/// Serves as the Clean Architecture abstraction boundary between domain logic
/// and concrete persistence data handlers (e.g. Isar database).
///
/// Implementations return entries sorted by date descending and bounded by a
/// cap, and surface persistence failures as `WeightRepositoryException`.
abstract class WeightRepository {
  /// Watches persisted weight records as a real-time reactive stream.
  ///
  /// Emits a new list of [WeightEntry] objects immediately upon subscription
  /// and whenever any entry is created, modified, or deleted in the underlying
  /// data store, bounded by the implementation's entry cap and sorted by date
  /// descending. May emit a stream error when the database stream fails.
  Stream<List<WeightEntry>> watchAllEntries();

  /// Fetches stored weight entries as a static single-shot list.
  ///
  /// Returns the most recent entries (bounded by the implementation's entry
  /// cap), sorted by date descending. Throws a `WeightRepositoryException`
  /// when local storage is unreadable.
  Future<List<WeightEntry>> getAllEntries();

  /// Persists a new or updated [entry] into the storage system.
  ///
  /// An unset id is assigned by the store. Throws a `WeightRepositoryException`
  /// when the write fails.
  Future<void> addEntry(WeightEntry entry);

  /// Removes the weight entry associated with the given [id].
  ///
  /// Throws a `WeightRepositoryException` when the deletion fails.
  Future<void> deleteEntry(int id);

  /// Bulk imports a collection of [entries] within a single transactional operation.
  ///
  /// Returns the number of records written. Throws a `WeightRepositoryException`
  /// when the transaction fails.
  Future<int> bulkImportEntries(List<WeightEntry> entries);

  /// Synchronizes remote entries into the local database with deduplication.
  /// Deduplication logic uses a 60-second and 0.05kg tolerance.
  Future<int> syncRemoteEntries(List<WeightEntry> remoteEntries);

  /// Removes all stored weight data from persistent storage.
  ///
  /// Throws a `WeightRepositoryException` when the wipe fails.
  Future<void> clearAllData();
}
