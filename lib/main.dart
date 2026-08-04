import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/data/repositories/isar_weight_repository.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/screens/app_initialization_error_screen.dart';

/// Entry point of the PureWeight application.
///
/// Bootstraps platform bindings, [HydratedBloc] storage, the [Isar] database
/// via [DatabaseModule], notifications, and the [AppSettingsBloc] before
/// running the app. On any initialization failure a crash log is appended and
/// [AppInitializationErrorScreen] is shown with a retry action.
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

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    } else {
      _writeCrashLog(details.exception, details.stack ?? StackTrace.current);
    }
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('Unhandled async error: $error\n$stack');
    } else {
      _writeCrashLog(error, stack);
    }
    return true;
  };

  try {
    final storageDirectory = HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    );
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: storageDirectory,
    );

    final isar = await DatabaseModule.initialize();
    final repository = _createWeightRepository(isar);

    await NotificationService.instance.initialize();

    final settingsBloc = AppSettingsBloc();

    runApp(
      BlocProvider(
        create: (_) => settingsBloc,
        child: App(repository: repository),
      ),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('App initialization failed: $error\n$stackTrace');
    }
    _writeCrashLog(error, stackTrace);

    runApp(AppInitializationErrorScreen(error: error, onRetry: () => main()));
  } finally {
    // Guarantee that the native splash screen is dismissed after initial frame render,
    // preventing screen flicker or stuck native splash screen assets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }
}

/// Creates the [WeightRepository] implementation backed by Isar.
///
/// Kept in [main.dart] as the composition root where the concrete type
/// is resolved, while the rest of the app only depends on the domain interface.
/// The repository is wired to [BiometricService.authenticationSuccesses] so
/// the encrypted watch stream re-subscribes as soon as the user authenticates.
WeightRepository _createWeightRepository(Isar isar) {
  return IsarWeightRepository(
    isar: isar,
    unlockSignal: BiometricService.instance.authenticationSuccesses,
  );
}

/// Appends an uncaught [error] to the on-device crash log in release builds.
///
/// Errors would otherwise vanish silently because the platform error handler
/// suppresses the default crash output. The log lives next to the database so
/// it survives restarts without introducing a new dependency.
Future<void> _writeCrashLog(Object error, StackTrace stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/crash_log.txt');
    final entry = '${DateTime.now().toIso8601String()}\n$error\n$stack\n\n';
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
  } catch (_) {
    // Crash logging must never throw.
  }
}
