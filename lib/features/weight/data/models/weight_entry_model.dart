import 'package:isar_community/isar.dart';

part 'weight_entry_model.g.dart';

/// An Isar collection model storing encrypted health data.
@collection
class WeightEntryModel {
  /// Creates an empty [WeightEntryModel] with default values.
  WeightEntryModel();

  /// The Isar auto-increment identifier.
  ///
  /// Kept in plaintext.
  Id id = Isar.autoIncrement;

  /// The encrypted body weight in kilograms.
  ///
  /// A Base64 string containing IV and AES-256 ciphertext.
  String encryptedWeight = '';

  /// The timestamp of the measurement.
  ///
  /// Kept in plaintext with an index for fast sorting and filtering.
  @Index()
  late DateTime dateTime;

  /// The encrypted optional user note.
  ///
  /// A Base64 string containing IV and AES-256 ciphertext.
  String? encryptedNote;
}
