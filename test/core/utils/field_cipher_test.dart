import 'dart:convert';
import 'dart:typed_data';

import 'package:balance/core/utils/field_cipher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldCipher', () {
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = i + 1;
    }

    group('encrypt', () {
      test('returns a non-empty base64 string', () {
        final result = FieldCipher.encrypt('75.4', key);
        expect(result, isNotEmpty);
        expect(() => base64Decode(result), returnsNormally);
      });

      test('returns a different IV on each call (randomness)', () {
        final encrypted1 = FieldCipher.encrypt('75.4', key);
        final encrypted2 = FieldCipher.encrypt('75.4', key);
        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('returns the same length payload', () {
        final encrypted1 = FieldCipher.encrypt('75.4', key);
        final encrypted2 = FieldCipher.encrypt('100.0', key);
        // Different plaintext lengths may produce different ciphertext lengths
        // but both should be valid base64
        expect(() => base64Decode(encrypted1), returnsNormally);
        expect(() => base64Decode(encrypted2), returnsNormally);
      });

      test('throws for empty string (AES-CBC limitation)', () {
        expect(() => FieldCipher.encrypt('', key), throwsA(isA<RangeError>()));
      });

      test('encrypts unicode string', () {
        final result = FieldCipher.encrypt('Hello 世界 🌍', key);
        expect(result, isNotEmpty);
        expect(() => base64Decode(result), returnsNormally);
      });
    });

    group('decrypt', () {
      test('decrypts to original plaintext', () {
        const original = '75.4';
        final encrypted = FieldCipher.encrypt(original, key);
        final decrypted = FieldCipher.decrypt(encrypted, key);
        expect(decrypted, equals(original));
      });

      test('throws for empty string encryption (AES-CBC limitation)', () {
        expect(() => FieldCipher.encrypt('', key), throwsA(isA<RangeError>()));
      });

      test('decrypts unicode string', () {
        const original = 'Hello 世界 🌍';
        final encrypted = FieldCipher.encrypt(original, key);
        final decrypted = FieldCipher.decrypt(encrypted, key);
        expect(decrypted, equals(original));
      });

      test('decrypts different plaintexts correctly', () {
        const original1 = '100.0';
        const original2 = '0.5';
        final encrypted1 = FieldCipher.encrypt(original1, key);
        final encrypted2 = FieldCipher.encrypt(original2, key);
        expect(FieldCipher.decrypt(encrypted1, key), equals(original1));
        expect(FieldCipher.decrypt(encrypted2, key), equals(original2));
      });

      test('throws FormatException for truncated payload', () {
        expect(
          () => FieldCipher.decrypt('c2hvcg==', key),
          throwsFormatException,
        );
      });

      test('throws FormatException for tampered payload', () {
        const original = '75.4';
        final encrypted = FieldCipher.encrypt(original, key);
        final decoded = base64Decode(encrypted);
        // Tamper with the ciphertext portion
        decoded[decoded.length - 1] ^= 0xFF;
        final tampered = base64Encode(decoded);
        expect(() => FieldCipher.decrypt(tampered, key), throwsFormatException);
      });

      test('throws FormatException for wrong key', () {
        const original = '75.4';
        final encrypted = FieldCipher.encrypt(original, key);
        final wrongKey = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          wrongKey[i] = 32 - i;
        }
        expect(
          () => FieldCipher.decrypt(encrypted, wrongKey),
          throwsFormatException,
        );
      });

      test('throws FormatException for invalid base64', () {
        expect(
          () => FieldCipher.decrypt('!!!invalid!!!', key),
          throwsFormatException,
        );
      });

      test('decrypts payload with IV length only', () {
        // Create a payload with only IV length (no MAC, no ciphertext beyond IV)
        final iv = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          iv[i] = i + 1;
        }
        // Only IV, no ciphertext - should fail
        expect(
          () => FieldCipher.decrypt(base64Encode(iv), key),
          throwsFormatException,
        );
      });
    });

    group('round-trip', () {
      test('multiple round-trips with same key', () {
        const values = ['75.4', '100.0', '0.5', 'Hello 世界 🌍'];
        for (final value in values) {
          final encrypted = FieldCipher.encrypt(value, key);
          final decrypted = FieldCipher.decrypt(encrypted, key);
          expect(decrypted, equals(value));
        }
      });

      test('round-trip with different keys', () {
        final key1 = Uint8List(32);
        final key2 = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          key1[i] = i + 1;
          key2[i] = 32 - i;
        }

        const original = '75.4';
        final encrypted1 = FieldCipher.encrypt(original, key1);
        final encrypted2 = FieldCipher.encrypt(original, key2);

        expect(FieldCipher.decrypt(encrypted1, key1), equals(original));
        expect(FieldCipher.decrypt(encrypted2, key2), equals(original));
        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });
  });
}
