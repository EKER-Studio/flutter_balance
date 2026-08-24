/// Categorized failure modes when parsing or analyzing CSV weight files.
enum CsvErrorType {
  /// File exceeds maximum allowed size.
  fileTooLarge,

  /// File contains unparseable or corrupted CSV structure.
  invalidFormat,

  /// File contains no valid weight records.
  noEntries,
}
