/// String capitalization helpers for user-facing text.
extension CapitalizeX on String {
  /// Returns a copy of this string with the first character uppercased.
  ///
  /// Returns the string unchanged when it is empty.
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
