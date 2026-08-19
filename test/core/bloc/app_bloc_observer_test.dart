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

class _NoopBlocObserver extends BlocObserver {
  const _NoopBlocObserver();
}

class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void triggerError(Object error) {
    addError(error, StackTrace.current);
  }
}

class _TestBlocEvent {}

class _TestBloc extends Bloc<_TestBlocEvent, int> {
  _TestBloc() : super(0) {
    on<_TestBlocEvent>((event, emit) {});
  }

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
    Bloc.observer = const _NoopBlocObserver();
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
        expect(content, contains('Unhandled error in _TestCubit'));
        expect(content, contains('_TestCubit'));

        await cubit.close();
      },
    );

    test(
      'records a StateError (Error subclass) with its message and type',
      () async {
        const observer = AppBlocObserver();
        Bloc.observer = observer;

        final cubit = _TestCubit();
        cubit.triggerError(StateError('state failure'));

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final content = await File(
          '${tempDir.path}/$crashLogFileName',
        ).readAsString();
        expect(content, contains('Bad state: state failure'));
        expect(content, contains('Unhandled error in _TestCubit'));

        await cubit.close();
      },
    );

    test('records errors raised from a Bloc, not only a Cubit', () async {
      const observer = AppBlocObserver();
      Bloc.observer = observer;

      final bloc = _TestBloc();
      bloc.triggerError(ArgumentError('bad argument'));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final content = await File(
        '${tempDir.path}/$crashLogFileName',
      ).readAsString();
      expect(content, contains('Invalid argument(s): bad argument'));
      expect(content, contains('Unhandled error in _TestBloc'));

      await bloc.close();
    });

    test('records arbitrary Object errors without throwing', () async {
      const observer = AppBlocObserver();
      Bloc.observer = observer;

      final cubit = _TestCubit();
      cubit.triggerError(Object());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final content = await File(
        '${tempDir.path}/$crashLogFileName',
      ).readAsString();
      expect(content, contains('Instance of'));
      expect(content, contains('Unhandled error in _TestCubit'));

      await cubit.close();
    });
  });
}
