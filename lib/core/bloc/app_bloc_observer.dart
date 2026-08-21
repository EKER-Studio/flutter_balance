import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/utils/crash_reporter.dart';

/// Global [BlocObserver] that automatically intercepts all unhandled BLoC errors
/// and forwards them to [AppCrashReporter] (Firebase Crashlytics and local log).
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppCrashReporter.recordError(
      error,
      stackTrace,
      reason: 'Unhandled error in ${bloc.runtimeType}',
      fatal: false,
    );
  }
}
