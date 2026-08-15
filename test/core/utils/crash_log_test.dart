import 'package:balance/core/utils/crash_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('crashLogFileName', () {
    test('is crash_log.txt', () {
      expect(crashLogFileName, 'crash_log.txt');
    });

    test('is a non-empty string', () {
      expect(crashLogFileName, isNotEmpty);
    });

    test('ends with .txt extension', () {
      expect(crashLogFileName.endsWith('.txt'), isTrue);
    });
  });
}
