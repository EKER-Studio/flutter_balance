/// Domain enumeration representing categorized failure modes in weight management workflows.
///
/// Emitted by weight domain logic and state management (e.g. BLoC) instead of raw exception
/// messages to decouple presentation layers from error strings and enable type-safe localization.
enum WeightErrorType {
  /// Indicates an unrecoverable failure while listening to the real-time weight entries stream.
  streamError,

  /// Indicates that a weight entry submission failed because the user's height parameter is missing or invalid.
  heightNotSet,

  /// Indicates a persistence failure while adding a new weight record to the repository.
  addEntryFailed,

  /// Indicates a deletion failure while attempting to remove a weight record from the repository.
  deleteEntryFailed,
}
