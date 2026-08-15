import 'dart:convert';
import 'dart:typed_data';

import 'package:balance/core/utils/field_cipher.dart';
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
      final text = 'héllo wörld 日本語';
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
}
