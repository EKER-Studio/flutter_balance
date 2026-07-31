import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// Provides Field-Level AES-256 CBC encryption and decryption services.
///
/// ## Security caveat
/// CBC alone provides confidentiality, NOT integrity: ciphertext can be
/// tampered with (e.g. bit-flipped) without detection, and padding-oracle
/// attacks against CBC are well documented. The threat model here is
/// at-rest protection of plaintext values in a local database file, not
/// defense against an adversary who can modify the database. If that
/// threat model ever changes (e.g. database syncing to a remote store),
/// switch to an authenticated mode (AES-GCM) or add a MAC over
/// `IV + ciphertext` before shipping.
class FieldCipher {
  /// Encrypts plaintext string using AES-256 CBC with a prepended random 16-byte IV.
  ///
  /// [plainText] Content string to encrypt.
  /// [keyBytes] 32-byte AES secret key.
  static String encrypt(String plainText, Uint8List keyBytes) {
    final encKey = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final combined = Uint8List(16 + encrypted.bytes.length);
    combined.setRange(0, 16, iv.bytes);
    combined.setRange(16, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  /// Decrypts Base64 payload containing IV + CipherText using AES-256 CBC.
  ///
  /// [base64String] Base64 encoded payload with prepended 16-byte IV.
  /// [keyBytes] 32-byte AES secret key.
  static String decrypt(String base64String, Uint8List keyBytes) {
    final combined = base64Decode(base64String);
    if (combined.length < 16) {
      throw const FormatException('Encrypted payload too short');
    }
    final ivBytes = combined.sublist(0, 16);
    final cipherBytes = combined.sublist(16);

    final encKey = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypted = enc.Encrypted(cipherBytes);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }
}
