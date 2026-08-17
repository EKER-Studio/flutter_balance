
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256 field-level encryption with HMAC-SHA256 integrity verification.
///
/// A utility for field-level AES-256 CBC encryption, decryption, and integrity verification.
///
/// Implements Encrypt-then-MAC using HMAC-SHA256 over `IV || Ciphertext` to guarantee
//// confidentiality, authenticity, and integrity against data corruption or bit-flipping.
class FieldCipher {
  static const int _ivLength = 16;
  static const int _macLength = 32;

  /// Encrypts the plaintext string using AES-256 CBC with a fresh random
  /// 16-byte IV and a 32-byte HMAC-SHA256 trailer.
  ///
  /// Payload format: `Base64(IV [16 B] + HMAC [32 B] + Ciphertext [N B])`.
  /// The ciphertext is PKCS#7-padded AES-256-CBC; the HMAC covers `IV ||
  /// Ciphertext`, so any tampering is detected by [decrypt].
  ///
  /// @param plainText Content string to encrypt.
  /// @param keyBytes 32-byte AES secret key.
  static String encrypt(String plainText, Uint8List keyBytes) {
    final encKey = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(_ivLength);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final ivAndCiphertext = Uint8List(_ivLength + encrypted.bytes.length);
    ivAndCiphertext.setRange(0, _ivLength, iv.bytes);
    ivAndCiphertext.setRange(
      _ivLength,
      ivAndCiphertext.length,
      encrypted.bytes,
    );

    final hmac = Hmac(sha256, keyBytes);
    final macBytes = hmac.convert(ivAndCiphertext).bytes;

    final combined = Uint8List(_ivLength + _macLength + encrypted.bytes.length);
    combined.setRange(0, _ivLength, iv.bytes);
    combined.setRange(_ivLength, _ivLength + _macLength, macBytes);
    combined.setRange(_ivLength + _macLength, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  /// Decrypts a Base64 payload, verifying the HMAC-SHA256 trailer first.
  ///
  /// The HMAC over `IV || Ciphertext` is recomputed and compared in constant
  /// time before any decryption happens. Payloads too short to carry a trailer
  /// (pre-HMAC `IV || Ciphertext` format written by older app versions) are
  /// decrypted through a legacy fallback path whose decryption failures still
  /// surface as a [FormatException].
  ///
  /// @param base64String Base64 encoded payload.
  /// @param keyBytes 32-byte AES secret key.
  /// Throws a FormatException if payload is truncated, corrupted, or integrity check fails.
  static String decrypt(String base64String, Uint8List keyBytes) {
    final combined = base64Decode(base64String);
    if (combined.length < _ivLength) {
      throw const FormatException('Encrypted payload too short');
    }

    final encKey = enc.Key(keyBytes);

    // Check if payload includes HMAC-SHA256 (length >= IV + MAC + block size)
    if (combined.length >= _ivLength + _macLength + 16) {
      final ivBytes = combined.sublist(0, _ivLength);
      final macBytes = combined.sublist(_ivLength, _ivLength + _macLength);
      final cipherBytes = combined.sublist(_ivLength + _macLength);

      final ivAndCiphertext = Uint8List(_ivLength + cipherBytes.length);
      ivAndCiphertext.setRange(0, _ivLength, ivBytes);
      ivAndCiphertext.setRange(_ivLength, ivAndCiphertext.length, cipherBytes);

      final hmac = Hmac(sha256, keyBytes);
      final computedMac = hmac.convert(ivAndCiphertext).bytes;

      if (_constantTimeEquals(macBytes, computedMac)) {
        final iv = enc.IV(ivBytes);
        final encrypted = enc.Encrypted(cipherBytes);
        final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
        return encrypter.decrypt(encrypted, iv: iv);
      }
    }

    // Fallback for legacy pre-HMAC payload: [16-byte IV] + [Ciphertext]
    final ivBytes = combined.sublist(0, _ivLength);
    final cipherBytes = combined.sublist(_ivLength);
    final iv = enc.IV(ivBytes);
    final encrypted = enc.Encrypted(cipherBytes);
    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));

    try {
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw FormatException(
        'Decryption or integrity verification failed: ${e.runtimeType}',
      );
    }
  }

  /// Compares byte arrays in constant time to prevent timing attacks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
