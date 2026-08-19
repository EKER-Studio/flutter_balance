import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:balance/core/utils/crash_log.dart';

/// Centralized crash reporting and non-fatal exception logging utility.
///
/// Dispatches errors to Firebase Crashlytics when available, while ensuring
/// release builds also append entries to the on-device [crashLogFileName]
/// and debug builds print to the console.
class AppCrashReporter {
  AppCrashReporter._();

  static bool _isFirebaseAvailable = false;

  /// Sets whether Firebase Crashlytics is active and available.
  static void setFirebaseAvailable(bool available) {
    _isFirebaseAvailable = available;
  }

  /// Records an [error] with optional [stack] trace and [reason] to Crashlytics
  /// and the local device log.
  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    final effectiveStack = stack ?? StackTrace.current;

    if (_isFirebaseAvailable) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          error,
          effectiveStack,
          reason: reason,
          fatal: fatal,
        );
      } catch (_) {
        // Crash reporting must never throw or disrupt application execution.
      }
    }

    if (kDebugMode) {
      final reasonStr = reason != null ? ' [Reason: $reason]' : '';
      debugPrint(
        '[AppCrashReporter] ${fatal ? "FATAL" : "NON-FATAL"}$reasonStr: $error\n$effectiveStack',
      );
    }

    await writeCrashLog(error, effectiveStack, reason: reason);
  }

  /// Maximum size of the crash log file before the oldest entries are trimmed.
  static const int _maxCrashLogBytes = 1024 * 1024;

  /// Appends an uncaught error to the on-device crash log.
  static Future<void> writeCrashLog(
    Object error,
    StackTrace stack, {
    dynamic reason,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$crashLogFileName');
      final reasonStr = reason != null ? ' [Reason: $reason]' : '';
      final entry =
          '${DateTime.now().toIso8601String()}$reasonStr\n$error\n$stack\n\n';

      if (await file.exists() && await file.length() > _maxCrashLogBytes) {
        await _trimCrashLog(file);
      }

      await file.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (_) {
      // Local logging must never throw.
    }
  }

  /// Removes the oldest half of [file] to avoid unbounded log growth.
  static Future<void> _trimCrashLog(File file) async {
    try {
      final content = await file.readAsString();
      final tail = content.substring(content.length ~/ 2);
      final firstEntryStart = tail.indexOf('\n\n');
      final kept = firstEntryStart == -1
          ? ''
          : tail.substring(firstEntryStart + 2);
      await file.writeAsString(kept, flush: true);
    } catch (_) {}
  }
}
