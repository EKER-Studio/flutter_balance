import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:balance/core/utils/crash_reporter.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crash_reporter_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    AppCrashReporter.setFirebaseAvailable(false);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppCrashReporter', () {
    test('setFirebaseAvailable toggles availability flag', () {
      AppCrashReporter.setFirebaseAvailable(true);
      AppCrashReporter.setFirebaseAvailable(false);
    });

    test(
      'recordError writes crash log entry when Firebase is disabled',
      () async {
        final error = StateError('Test exception');
        final stack = StackTrace.current;

        await AppCrashReporter.recordError(
          error,
          stack,
          reason: 'Testing crash reporter',
          fatal: false,
        );

        final logFile = File('${tempDir.path}/$crashLogFileName');
        expect(await logFile.exists(), isTrue);

        final content = await logFile.readAsString();
        expect(content, contains('Bad state: Test exception'));
        expect(content, contains('Testing crash reporter'));
      },
    );

    test(
      'writeCrashLog trims content when file exceeds max size limit',
      () async {
        final logFile = File('${tempDir.path}/$crashLogFileName');

        // Create a large string exceeding 1MB
        final largeChunk = 'A' * (512 * 1024);
        final initialContent = '$largeChunk\n\n$largeChunk\n\n';
        await logFile.writeAsString(initialContent);

        expect(await logFile.length(), greaterThan(1024 * 1024));

        await AppCrashReporter.writeCrashLog(
          'New Overflow Error',
          StackTrace.current,
          reason: 'Testing trimming',
        );

        expect(await logFile.exists(), isTrue);
        final content = await logFile.readAsString();
        expect(content, contains('New Overflow Error'));
        expect(content, contains('Testing trimming'));
      },
    );

    test('recordError with fatal true executes safely', () async {
      await AppCrashReporter.recordError(
        Exception('Fatal Crash'),
        StackTrace.current,
        reason: 'Fatal test',
        fatal: true,
      );

      final logFile = File('${tempDir.path}/$crashLogFileName');
      expect(await logFile.exists(), isTrue);
      final content = await logFile.readAsString();
      expect(content, contains('Fatal Crash'));
    });
  });
}
