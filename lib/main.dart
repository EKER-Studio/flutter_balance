import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/app.dart';
import 'package:balance/core/utils/crash_log.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/presentation/screens/app_initialization_error_screen.dart';

/// Serves as the entry point of the Balance application.
///
/// Bootstraps platform bindings, HydratedBloc storage, and the [AppSettingsBloc]
/// before running the app. Heavy asynchronous initializations (Isar, Notifications, etc.)
/// are deferred to [App], which displays a theme-aware splash screen during loading.
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

    final settingsBloc = AppSettingsBloc();

    runApp(BlocProvider(create: (_) => settingsBloc, child: const App()));
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('App storage initialization failed: $error\n$stackTrace');
    }
    _writeCrashLog(error, stackTrace);

    // Remove the splash manually when storage initialization fails.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    runApp(AppInitializationErrorScreen(error: error, onRetry: () => main()));
  }
}

/// Maximum size of the crash log file before the oldest entries are trimmed.
///
/// Prevents the log from growing without bound during long-running installs or
/// crash loops, at the cost of at most one extra entry past this limit.
const int _maxCrashLogBytes = 1024 * 1024;

/// Appends an uncaught [error] to the on-device crash log in release builds.
///
/// Errors would otherwise vanish silently because the platform error handler
/// suppresses the default crash output. The log lives next to the database so
/// it survives restarts without introducing a new dependency.
Future<void> _writeCrashLog(Object error, StackTrace stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$crashLogFileName');
    final entry = '${DateTime.now().toIso8601String()}\n$error\n$stack\n\n';

    if (await file.exists() && await file.length() > _maxCrashLogBytes) {
      await _trimCrashLog(file);
    }

    await file.writeAsString(entry, mode: FileMode.append, flush: true);
  } catch (_) {
    // Crash logging must never throw.
  }
}

/// Removes the oldest half of [file], aligned to an entry boundary, so the
/// newest crash entries survive and the log never exceeds the cap by much.
Future<void> _trimCrashLog(File file) async {
  final content = await file.readAsString();
  final tail = content.substring(content.length ~/ 2);
  final firstEntryStart = tail.indexOf('\n\n');
  final kept = firstEntryStart == -1 ? '' : tail.substring(firstEntryStart + 2);
  await file.writeAsString(kept, flush: true);
}
