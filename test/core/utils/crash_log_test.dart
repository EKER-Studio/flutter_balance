import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/crash_log.dart';

void main() {
  group('crashLogFileName', () {
    test('is a non-empty string', () {
      expect(crashLogFileName, isA<String>());
      expect(crashLogFileName, isNotEmpty);
    });

    test('has .txt extension', () {
      expect(crashLogFileName, endsWith('.txt'));
    });

    test('contains crash_log prefix', () {
      expect(crashLogFileName, startsWith('crash_log'));
    });

    test('is exactly crash_log.txt', () {
      expect(crashLogFileName, 'crash_log.txt');
    });
  });
}
