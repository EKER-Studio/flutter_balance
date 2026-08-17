/// Domain entity for body weight measurements, including valid value bounds.

/// A domain entity representing an individual body weight measurement.
///
/// Encapsulates core domain data for weight tracking, including weight in kilograms,
/// measurement timestamp, and an optional user note.
//// Values are expected to lie within [minWeightKg] and [maxWeightKg] (inclusive).


class WeightEntry {
  /// The minimum valid body weight in kilograms, inclusive.
  static const double minWeightKg = 20;

  /// The maximum valid body weight in kilograms, inclusive.
  static const double maxWeightKg = 300;

  /// The unique database primary key identifier.
  ///
  /// Defaults to 0 for unpersisted entries.
  final int id;

  /// The recorded body weight value in kilograms.
  final double weightKg;

  /// The date and time when the weight measurement was recorded.
  final DateTime dateTime;

  /// An optional user-provided text note accompanying the weight record.
  final String? note;

  /// Creates an immutable [WeightEntry] domain entity instance.
  ///
  /// The [weightKg] and [dateTime] parameters are mandatory.
  /// Parameter [id] defaults to 0 for new unsaved entries.
  /// Parameter [note] is optional.
  const WeightEntry({
    this.id = 0,
    required this.weightKg,
    required this.dateTime,
    this.note,
  });
}
