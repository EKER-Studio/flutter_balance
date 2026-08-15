import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/utils/crash_log.dart';

void main() {
  group('crash_log', () {
    test('crashLogFileName equals crash_log.txt', () {
      expect(crashLogFileName, 'crash_log.txt');
    });
  });
}
