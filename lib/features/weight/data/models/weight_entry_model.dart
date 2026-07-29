import 'package:isar_community/isar.dart';

part 'weight_entry_model.g.dart';

/// Isar collection model storing encrypted health data.
@collection
class WeightEntryModel {
  /// Creates an empty model with default values.
  WeightEntryModel();

  /// Isar auto-increment identifier (kept in plaintext).
  Id id = Isar.autoIncrement;

  /// Encrypted body weight in kg (Base64 string containing IV + AES-256 ciphertext).
  String encryptedWeight = '';

  /// Timestamp of the measurement (kept in plaintext with index for fast sorting/filtering).
  @Index()
  late DateTime dateTime;

  /// Encrypted optional user note (Base64 string containing IV + AES-256 ciphertext).
  String? encryptedNote;
}
