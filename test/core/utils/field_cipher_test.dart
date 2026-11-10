import 'dart:convert';
import 'dart:typed_data';

import 'package:balance/core/utils/field_cipher.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List makeKey(int seed) {
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = (seed + i) % 256;
    }
    return bytes;
  }

  /// Builds an authenticated `IV || HMAC || Ciphertext` payload that used the
  /// *raw* master key for **both** AES-256-CBC and HMAC-SHA256 — i.e. the
  /// on-disk format written before HKDF key separation was introduced.
  String encryptRawKey(String plainText, Uint8List key) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(key), mode: enc.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final ivAndCiphertext = Uint8List(16 + encrypted.bytes.length)
      ..setRange(0, 16, iv.bytes)
      ..setRange(16, 16 + encrypted.bytes.length, encrypted.bytes);

    final mac = Hmac(sha256, key).convert(ivAndCiphertext).bytes;

    final totalLength = 16 + 32 + encrypted.bytes.length;
    final combined = Uint8List(totalLength)
      ..setRange(0, 16, iv.bytes)
      ..setRange(16, 16 + 32, mac)
      ..setRange(16 + 32, totalLength, encrypted.bytes);
    return base64Encode(combined);
  }

  group('encrypt', () {
    test('produces a valid base64 string', () {
      final key = makeKey(42);
      final result = FieldCipher.encrypt('hello', key);
      expect(base64Decode(result), isA<List<int>>());
    });

    test('payload length is at least IV + MAC + one AES block', () {
      final key = makeKey(42);
      final result = FieldCipher.encrypt('test', key);
      final decoded = base64Decode(result);
      expect(decoded.length, greaterThanOrEqualTo(16 + 32 + 16));
    });

    test('two encryptions of same plaintext differ (random IV)', () {
      final key = makeKey(7);
      final a = FieldCipher.encrypt('same', key);
      final b = FieldCipher.encrypt('same', key);
      expect(a, isNot(equals(b)));
    });

    test('different plaintexts produce different payloads', () {
      final key = makeKey(9);
      final a = FieldCipher.encrypt('aaa', key);
      final b = FieldCipher.encrypt('bbb', key);
      expect(a, isNot(equals(b)));
    });
  });

  group('decrypt', () {
    test('round-trips a plaintext string', () {
      final key = makeKey(42);
      final cipherText = FieldCipher.encrypt('75.4', key);
      expect(FieldCipher.decrypt(cipherText, key), '75.4');
    });

    test('round-trips a long string', () {
      final key = makeKey(42);
      final longText = 'a' * 200;
      final cipherText = FieldCipher.encrypt(longText, key);
      expect(FieldCipher.decrypt(cipherText, key), longText);
    });

    test('round-trips unicode text', () {
      final key = makeKey(42);
      const text = 'héllo wörld 日本語';
      final cipherText = FieldCipher.encrypt(text, key);
      expect(FieldCipher.decrypt(cipherText, key), text);
    });

    test('throws FormatException for payload too short', () {
      final key = makeKey(42);
      final shortPayload = base64Encode(Uint8List(10));
      expect(
        () => FieldCipher.decrypt(shortPayload, key),
        throwsFormatException,
      );
    });

    test('throws FormatException for corrupted MAC', () {
      final key = makeKey(42);
      final cipherText = FieldCipher.encrypt('secret', key);
      final decoded = base64Decode(cipherText);
      final corrupted = Uint8List.fromList(decoded);
      corrupted[20] ^= 0xFF;
      expect(
        () => FieldCipher.decrypt(base64Encode(corrupted), key),
        throwsFormatException,
      );
    });

    test('throws FormatException for wrong key', () {
      final key1 = makeKey(42);
      final key2 = makeKey(99);
      final cipherText = FieldCipher.encrypt('data', key1);
      expect(
        () => FieldCipher.decrypt(cipherText, key2),
        throwsFormatException,
      );
    });

    test('throws FormatException for invalid base64', () {
      final key = makeKey(42);
      expect(
        () => FieldCipher.decrypt('not-valid-base64!!!', key),
        throwsFormatException,
      );
    });
  });

  group('legacy fallback (pre-HMAC payload)', () {
    test('identifies legacy and authenticated payload formats', () {
      final keyBytes = makeKey(42);
      final encKey = enc.Key(keyBytes);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt('legacy', iv: iv);
      final legacyBytes = Uint8List(16 + encrypted.bytes.length)
        ..setRange(0, 16, iv.bytes)
        ..setRange(16, 16 + encrypted.bytes.length, encrypted.bytes);

      expect(FieldCipher.isLegacyPayload(base64Encode(legacyBytes)), isTrue);
      expect(
        FieldCipher.isLegacyPayload(FieldCipher.encrypt('current', keyBytes)),
        isFalse,
      );
    });

    test('decrypts a legacy IV+ciphertext payload', () {
      final keyBytes = makeKey(42);
      final encKey = enc.Key(keyBytes);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt('legacy', iv: iv);

      final combined = Uint8List(16 + encrypted.bytes.length);
      combined.setRange(0, 16, iv.bytes);
      combined.setRange(16, combined.length, encrypted.bytes);

      final result = FieldCipher.decrypt(base64Encode(combined), keyBytes);
      expect(result, 'legacy');
    });

    test('throws FormatException when legacy payload decryption fails', () {
      final keyBytes = makeKey(42);
      // Construct a payload of length between 16 and 16 + 32 + 16 (e.g. 16 + 16 = 32 bytes) with corrupt ciphertext
      final corruptLegacy = Uint8List(32);
      expect(
        () => FieldCipher.decrypt(base64Encode(corruptLegacy), keyBytes),
        throwsFormatException,
      );
    });
  });

  group('HMAC integrity', () {
    test('flipping a single bit in ciphertext causes failure', () {
      final key = makeKey(42);
      final cipherText = FieldCipher.encrypt('integrity', key);
      final decoded = base64Decode(cipherText);
      final corrupted = Uint8List.fromList(decoded);
      final lastByte = corrupted.length - 1;
      corrupted[lastByte] ^= 1;
      expect(
        () => FieldCipher.decrypt(base64Encode(corrupted), key),
        throwsFormatException,
      );
    });
  });

  group('raw-key backward compatibility (pre key-separation)', () {
    test('decrypts an authenticated payload that used the raw key for both '
        'AES and HMAC', () {
      final key = makeKey(42);
      final payload = encryptRawKey('75.4', key);
      expect(FieldCipher.decrypt(payload, key), '75.4');
    });

    test('does not accept a raw-key payload under a different key', () {
      final key1 = makeKey(42);
      final key2 = makeKey(99);
      final payload = encryptRawKey('secret', key1);
      expect(() => FieldCipher.decrypt(payload, key2), throwsFormatException);
    });
  });

  group('key separation', () {
    test('new payload MAC is computed with a derived key, not the raw master '
        'key', () {
      final key = makeKey(42);
      final payload = FieldCipher.encrypt('75.4', key);
      final decoded = Uint8List.fromList(base64Decode(payload));
      // Layout: IV[16] | MAC[32] | Ciphertext[N].
      final iv = decoded.sublist(0, 16);
      final cipherBytes = decoded.sublist(16 + 32);
      final ivAndCiphertext = Uint8List(16 + cipherBytes.length)
        ..setRange(0, 16, iv)
        ..setRange(16, 16 + cipherBytes.length, cipherBytes);
      // Recompute the MAC under the *raw* master key and substitute it.
      final rawMac = Hmac(sha256, key).convert(ivAndCiphertext).bytes;
      final tampered = Uint8List.fromList(decoded)
        ..setRange(16, 16 + 32, rawMac);
      // If the MAC key were the raw master key, this substitution would verify;
      // it must instead fail, proving the MAC uses an independent derived key.
      expect(
        () => FieldCipher.decrypt(base64Encode(tampered), key),
        throwsFormatException,
      );
    });
  });
}
