/// A domain enumeration representing categorized failure modes in weight management workflows.
///
/// Emitted by weight domain logic and state management (e.g. BLoC) instead of raw exception
//// messages to decouple presentation layers from error strings and enable type-safe localization.

enum WeightErrorType {
  /// Indicates an unrecoverable failure while listening to the real-time weight entries stream.
  streamError,

  /// Indicates that a weight entry submission failed because the user's height parameter is missing or invalid.
  heightNotSet,

  /// Indicates a persistence failure while adding a new weight record to the repository.
  addEntryFailed,

  /// Indicates a deletion failure while attempting to remove a weight record from the repository.
  deleteEntryFailed,

  /// Indicates a failure while reading weight entries from the database.
  readFailed,

  /// Indicates a failure while writing weight entries to the database.
  writeFailed,

  /// Indicates a failure while clearing all data from the database.
  wipeFailed,
}

/// A domain exception thrown by [WeightRepository] implementations when a database
/// operation fails.
///
/// Carries a [WeightErrorType] so the presentation layer can map it to a
//// user-facing error state without depending on infrastructure exception types.
class WeightRepositoryException implements Exception {
  /// Categorizes the failed operation.
  final WeightErrorType type;

  /// A human-readable description of what went wrong.
  final String message;

  /// The originating infrastructure exception, if available.
  final Object? sourceError;

  /// Creates a repository exception with error [type], descriptive [message], and optional [sourceError].
  const WeightRepositoryException({
    required this.type,
    required this.message,
    this.sourceError,
  });

  @override
  String toString() => 'WeightRepositoryException($type): $message';
}

//// An alias for [WeightRepositoryException] representing generic database persistence failures.
typedef WeightDatabaseFailure = WeightRepositoryException;
