import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Provides field-level AES-256-CBC encryption and HMAC-SHA256 integrity
/// verification.
///
/// Uses Encrypt-then-MAC over `IV || Ciphertext` to guarantee confidentiality,
/// authenticity, and protection against bit-flipping attacks.
///
/// **Key separation.** A single 32-byte master key is passed to [encrypt] and
/// [decrypt], but it is *never* used directly for both confidentiality and
/// integrity. Instead, two independent sub-keys are derived from the master key
/// with HKDF-SHA256 (RFC 5869), each bound to a distinct `info` context:
///
///   * `encKey` (32 B) — used only for AES-256-CBC encryption
///   * `macKey` (32 B) — used only for the HMAC-SHA256 trailer
///
/// This closes the well-known weakness of reusing one key across two
/// cryptographic primitives (related-key / cross-protocol attacks) while keeping
/// the public API and the on-disk payload layout unchanged.
///
/// **Backward compatibility.** Payloads written before key separation used the
/// raw master key for *both* AES and HMAC. [decrypt] therefore tries the
/// HKDF-derived keys first and transparently falls back to the raw-key scheme
/// (and finally to the unauthenticated pre-HMAC legacy format), so existing
/// encrypted data decrypts without a migration.
class FieldCipher {
  static const int _ivLength = 16;
  static const int _macLength = 32;
  static const int _keyLength = 32;

  /// HKDF `info` context strings. Distinct, non-overlapping contexts guarantee
  /// that the derived encryption and MAC sub-keys are cryptographically
  /// independent even though they share the same master key.
  static const String _encInfo = 'balance/field-cipher/aes-enc/v1';
  static const String _macInfo = 'balance/field-cipher/hmac-mac/v1';

  /// Fixed HKDF salt. A fixed, application-specific salt (rather than a random
  /// one) keeps derivation deterministic, so the same master key always yields
  /// the same sub-keys — which [decrypt] relies on to re-derive them.
  static final Uint8List _hkdfSalt = utf8.encode(
    'balance/field-cipher/hkdf-salt/v1',
  );

  /// Reports whether [base64String] uses the unauthenticated pre-HMAC format.
  ///
  /// Detection is purely length-based and therefore independent of the key
  /// scheme: the authenticated (raw-key or HKDF) formats are distinguished from
  /// the legacy one only by the presence of a 32-byte MAC trailer.
  static bool isLegacyPayload(String base64String) {
    final combined = base64Decode(base64String);
    if (combined.length < _ivLength) {
      throw const FormatException('Encrypted payload too short');
    }
    return combined.length < _ivLength + _macLength + 16;
  }

  /// Encrypts [plainText] using AES-256 CBC with a fresh random IV and a
  /// 32-byte HMAC-SHA256 trailer, deriving independent encryption and MAC
  /// sub-keys from [keyBytes] via HKDF-SHA256.
  ///
  /// Payload format: `Base64(IV [16 B] + HMAC [32 B] + Ciphertext [N B])`.
  /// The HMAC covers `IV || Ciphertext`, so any tampering is detected by
  /// [decrypt]. [keyBytes] must be exactly 32 bytes.
  static String encrypt(String plainText, Uint8List keyBytes) {
    final (encKey, macKey) = _deriveKeys(keyBytes);
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

    final macBytes = Hmac(sha256, macKey).convert(ivAndCiphertext).bytes;

    final combined = Uint8List(_ivLength + _macLength + encrypted.bytes.length);
    combined.setRange(0, _ivLength, iv.bytes);
    combined.setRange(_ivLength, _ivLength + _macLength, macBytes);
    combined.setRange(_ivLength + _macLength, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  /// Decrypts a Base64 payload produced by [encrypt], verifying the
  /// HMAC-SHA256 trailer before any decryption happens.
  ///
  /// Decryption is attempted in three fallback stages, each gated by a strong
  /// 256-bit integrity check, so existing data decrypts without a migration:
  ///
  ///   1. **HKDF scheme** (current): the MAC and ciphertext are checked against
  ///      the HKDF-derived sub-keys. This is the path for data written by the
  ///      current version.
  ///   2. **Raw-key scheme** (pre key-separation): the MAC and ciphertext are
  ///      checked against the raw master key. This transparently decrypts
  ///      authenticated payloads written before key separation was introduced.
  ///   3. **Legacy pre-HMAC scheme**: a payload too short to carry a trailer is
  ///      decrypted with the raw master key without authentication.
  ///
  /// Throws a [FormatException] if the payload is truncated, corrupted, or
  /// fails every integrity check. [keyBytes] must be exactly 32 bytes.
  static String decrypt(String base64String, Uint8List keyBytes) {
    final combined = base64Decode(base64String);
    if (combined.length < _ivLength) {
      throw const FormatException('Encrypted payload too short');
    }

    // Authenticated formats (HKDF or raw-key): length >= IV + MAC + one block.
    if (combined.length >= _ivLength + _macLength + 16) {
      final ivBytes = combined.sublist(0, _ivLength);
      final macBytes = combined.sublist(_ivLength, _ivLength + _macLength);
      final cipherBytes = combined.sublist(_ivLength + _macLength);

      final ivAndCiphertext = Uint8List(_ivLength + cipherBytes.length);
      ivAndCiphertext.setRange(0, _ivLength, ivBytes);
      ivAndCiphertext.setRange(_ivLength, ivAndCiphertext.length, cipherBytes);

      // Stage 1: current HKDF-derived sub-keys.
      final derived = _deriveKeys(keyBytes);
      final computedMac = Hmac(
        sha256,
        derived.$2,
      ).convert(ivAndCiphertext).bytes;
      if (_constantTimeEquals(macBytes, computedMac)) {
        return _decryptWith(derived.$1, ivBytes, cipherBytes);
      }

      // Stage 2: legacy raw-key scheme (pre key-separation).
      final rawMac = Hmac(sha256, keyBytes).convert(ivAndCiphertext).bytes;
      if (_constantTimeEquals(macBytes, rawMac)) {
        return _decryptWith(enc.Key(keyBytes), ivBytes, cipherBytes);
      }

      throw const FormatException('HMAC integrity verification failed');
    }

    // Stage 3: legacy pre-HMAC payload: [16-byte IV] + [Ciphertext].
    final ivBytes = combined.sublist(0, _ivLength);
    final cipherBytes = combined.sublist(_ivLength);
    return _decryptWith(enc.Key(keyBytes), ivBytes, cipherBytes);
  }

  /// Decrypts [cipherBytes] (with [ivBytes]) under [aesKey], translating any
  /// low-level failure into a [FormatException].
  static String _decryptWith(
    enc.Key aesKey,
    List<int> ivBytes,
    List<int> cipherBytes,
  ) {
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypted = enc.Encrypted(Uint8List.fromList(cipherBytes));
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    try {
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw FormatException('Decryption failed: ${e.runtimeType}');
    }
  }

  /// Derives the independent AES encryption key and HMAC key from the 32-byte
  /// [masterKey] using HKDF-SHA256 (RFC 5869) with distinct `info` contexts.
  static (enc.Key, Uint8List) _deriveKeys(Uint8List masterKey) {
    final encKey = _hkdfSha256(masterKey, info: _encInfo);
    final macKey = _hkdfSha256(masterKey, info: _macInfo);
    return (enc.Key(encKey), macKey);
  }

  /// HKDF-SHA256 key derivation (RFC 5869) producing [length] bytes from
  /// [ikm] using the fixed [_hkdfSalt] and an application-specific [info]
  /// context.
  ///
  ///   * Extract: `PRK = HMAC(salt, IKM)`
  ///   * Expand:  `OKM = T(1) | T(2) | ...`, where `T(i) = HMAC(PRK, T(i-1)|info|i)`
  static Uint8List _hkdfSha256(
    Uint8List ikm, {
    required String info,
    int length = _keyLength,
  }) {
    final prk = Hmac(sha256, _hkdfSalt).convert(ikm).bytes;

    final infoBytes = utf8.encode(info);
    final okm = BytesBuilder();
    List<int> previous = const <int>[];
    for (var counter = 1; okm.length < length; counter++) {
      final input = <int>[...previous, ...infoBytes, counter];
      previous = Hmac(sha256, prk).convert(input).bytes;
      okm.add(previous);
    }
    return Uint8List.sublistView(okm.toBytes(), 0, length);
  }

  /// Compares two byte arrays in constant time to prevent timing attacks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
