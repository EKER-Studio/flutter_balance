import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/field_cipher.dart';

void main() {
  group('FieldCipher Unit Tests', () {
    final keyA = Uint8List.fromList(List.generate(32, (i) => i));
    final keyB = Uint8List.fromList(List.generate(32, (i) => i + 1));

    test(
      'encrypt produces valid Base64 payload and decrypt restores original text',
      () {
        const plainText = '78.5';
        final encrypted = FieldCipher.encrypt(plainText, keyA);

        expect(encrypted, isNot(contains(plainText)));
        expect(() => base64Decode(encrypted), returnsNormally);

        final decrypted = FieldCipher.decrypt(encrypted, keyA);
        expect(decrypted, plainText);
      },
    );

    test('decrypt with incorrect key throws exception', () {
      const plainText = 'Secret Note';
      final encrypted = FieldCipher.encrypt(plainText, keyA);

      expect(() => FieldCipher.decrypt(encrypted, keyB), throwsA(anything));
    });

    test('decrypt with non-Base64 malformed string throws FormatException', () {
      const malformed = r'%%%NOT_VALID_BASE64$$$';

      expect(
        () => FieldCipher.decrypt(malformed, keyA),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'decrypt with payload shorter than 16 bytes throws FormatException',
      () {
        final shortPayload = base64Encode(Uint8List.fromList([1, 2, 3, 4, 5]));

        expect(
          () => FieldCipher.decrypt(shortPayload, keyA),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('tampered ciphertext fails MAC verification and throws exception', () {
      const plainText = '82.4';
      final encrypted = FieldCipher.encrypt(plainText, keyA);
      final rawBytes = base64Decode(encrypted);

      // Flip a bit in the ciphertext section
      rawBytes[rawBytes.length - 1] ^= 0xFF;
      final tampered = base64Encode(rawBytes);

      expect(
        () => FieldCipher.decrypt(tampered, keyA),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
