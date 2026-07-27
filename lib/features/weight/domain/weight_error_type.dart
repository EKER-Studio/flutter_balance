/// Typed error reasons emitted by [WeightBloc].
///
/// Used instead of raw [String] messages so the presentation layer can map
/// each reason to a localized user-facing string without introducing a
/// [BuildContext] dependency into the Bloc layer.
enum WeightErrorType {
  /// The stream subscription failed.
  streamError,

  /// User attempted to add a weight entry without setting their height first.
  heightNotSet,

  /// The repository threw when persisting a new entry.
  addEntryFailed,

  /// The repository threw when removing an entry.
  deleteEntryFailed,
}
