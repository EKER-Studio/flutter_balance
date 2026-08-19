import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:balance/core/bloc/app_bloc_observer.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:balance/core/utils/crash_reporter.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void triggerError(Object error) {
    addError(error, StackTrace.current);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bloc_observer_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    AppCrashReporter.setFirebaseAvailable(false);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AppBlocObserver', () {
    test(
      'intercepts BLoC errors and writes them via AppCrashReporter',
      () async {
        const observer = AppBlocObserver();
        Bloc.observer = observer;

        final cubit = _TestCubit();
        cubit.triggerError(Exception('Cubit Error Occurred'));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final logFile = File('${tempDir.path}/$crashLogFileName');
        expect(await logFile.exists(), isTrue);

        final content = await logFile.readAsString();
        expect(content, contains('Exception: Cubit Error Occurred'));
        expect(content, contains('_TestCubit'));

        await cubit.close();
      },
    );
  });
}
