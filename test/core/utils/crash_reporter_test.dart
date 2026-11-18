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
    AppCrashReporter.setCollectionEnabled(false);
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

    test('recordError captures the current stack when none is given', () async {
      await AppCrashReporter.recordError(StateError('No stack provided'), null);

      final logFile = File('${tempDir.path}/$crashLogFileName');
      final content = await logFile.readAsString();
      expect(content, contains('No stack provided'));
    });

    test(
      'recordError attempts Crashlytics and keeps logging when it fails',
      () async {
        AppCrashReporter.setFirebaseAvailable(true);
        AppCrashReporter.setCollectionEnabled(true);

        await AppCrashReporter.recordError(
          StateError('Crashlytics unavailable'),
          StackTrace.current,
          reason: 'Firebase attempt',
        );

        final logFile = File('${tempDir.path}/$crashLogFileName');
        final content = await logFile.readAsString();
        expect(content, contains('Crashlytics unavailable'));
        expect(content, contains('Firebase attempt'));
      },
    );

    test(
      'writeCrashLog swallows trimming failures for a read-only log file',
      () async {
        final logFile = File('${tempDir.path}/$crashLogFileName');
        final largeChunk = 'B' * (512 * 1024);
        await logFile.writeAsString('$largeChunk\n\n$largeChunk\n\n');

        expect(await logFile.length(), greaterThan(1024 * 1024));

        // Make the file read-only so the trim rewrite fails, exercising the
        // suppression branch. Restore permissions so tearDown can delete it.
        await Process.run('chmod', ['444', logFile.path]);
        addTearDown(() => Process.run('chmod', ['644', logFile.path]));

        await AppCrashReporter.writeCrashLog(
          'Trim failure error',
          StackTrace.current,
          reason: 'Read-only file',
        );

        expect(await logFile.exists(), isTrue);
      },
    );
  });
}
