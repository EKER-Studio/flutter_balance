import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Interface for weight data access.
abstract class WeightRepository {
  /// Returns a reactive stream that emits the full list of entries on every change.
  Stream<List<WeightEntry>> watchAllEntries();

  /// Returns all stored weight entries as a single synchronous list.
  Future<List<WeightEntry>> getAllEntries();

  /// Persists a new [entry] and returns the generated id.
  Future<void> addEntry(WeightEntry entry);

  /// Deletes the entry identified by [id].
  Future<void> deleteEntry(int id);

  /// Bulk imports [entries] into the database within a single transaction.
  ///
  /// Entries with matching IDs are updated; new entries are inserted.
  /// Returns the number of successfully imported entries.
  Future<int> bulkImportEntries(List<WeightEntry> entries);
}
