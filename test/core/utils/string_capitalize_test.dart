import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/string_capitalize.dart';

void main() {
  group('CapitalizeX.capitalizeFirst', () {
    test('returns unchanged empty string', () {
      expect(''.capitalizeFirst(), equals(''));
    });

    test('capitalizes single lowercase character', () {
      expect('a'.capitalizeFirst(), equals('A'));
    });

    test('keeps single uppercase character uppercase', () {
      expect('A'.capitalizeFirst(), equals('A'));
    });

    test('capitalizes first letter of all lowercase string', () {
      expect('weight'.capitalizeFirst(), equals('Weight'));
    });

    test('preserves subsequent characters in mixed case string', () {
      expect('wEiGhT'.capitalizeFirst(), equals('WEiGhT'));
    });

    test('leaves string unchanged when starting with number or symbol', () {
      expect('123abc'.capitalizeFirst(), equals('123abc'));
      expect('_weight'.capitalizeFirst(), equals('_weight'));
    });

    test('correctly capitalizes accented/Unicode characters', () {
      expect('środa'.capitalizeFirst(), equals('Środa'));
      expect('łąka'.capitalizeFirst(), equals('Łąka'));
    });
  });
}
