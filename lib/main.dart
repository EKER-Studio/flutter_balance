import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/app.dart';
import 'package:balance/core/bloc/app_bloc_observer.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/core/presentation/screens/app_initialization_error_screen.dart';
import 'package:balance/firebase_options.dart';

/// Serves as the entry point of the Balance application.
///
/// Bootstraps platform bindings, HydratedBloc storage, Firebase services, and
/// the [AppSettingsBloc] before running the app. Heavy asynchronous
/// resources (Isar, NotificationService, Health) are initialized lazily inside
/// [App] while [AppSplashScreen] remains visible.
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Configure transparent system overlays to match splash & theme background seamlessly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Install global BLoC error observer to report any unhandled BLoC errors.
  Bloc.observer = const AppBlocObserver();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppCrashReporter.setFirebaseAvailable(true);
    AppAnalytics.setFirebaseAvailable(true);
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      await AppAnalytics.setAnalyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      await AppAnalytics.setAnalyticsCollectionEnabled(true);
    }
  } catch (error, stackTrace) {
    AppCrashReporter.setFirebaseAvailable(false);
    AppAnalytics.setFirebaseAvailable(false);
    if (kDebugMode) {
      debugPrint(
        '[Firebase] Initialization skipped or failed: $error\n$stackTrace',
      );
    }
  }

  // Route framework errors to Crashlytics and local crash log in release builds.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppCrashReporter.recordError(
      details.exception,
      details.stack,
      reason: 'FlutterError: ${details.context?.toDescription()}',
      fatal: true,
    );
  };

  // Route asynchronous platform errors to Crashlytics and local crash log in release builds.
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppCrashReporter.recordError(
      error,
      stack,
      reason: 'Unhandled asynchronous platform error',
      fatal: true,
    );
    return true;
  };

  try {
    final storageDirectory = HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    );
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: storageDirectory,
    );

    final settingsBloc = AppSettingsBloc();

    runApp(BlocProvider(create: (_) => settingsBloc, child: const App()));
  } catch (error, stackTrace) {
    AppCrashReporter.recordError(
      error,
      stackTrace,
      reason: 'App storage initialization failed',
      fatal: true,
    );

    // Remove the splash manually when storage initialization fails.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    runApp(AppInitializationErrorScreen(error: error, onRetry: () => main()));
  }
}
