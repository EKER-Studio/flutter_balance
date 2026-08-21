import 'dart:async';
import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';

import 'package:balance/core/integrations/biometrics/biometric_service.dart';

/// Enforces the biometric app lock and database integrity across app lifecycle changes.
///
/// Registers itself as a [WidgetsBindingObserver] and reacts to lifecycle
/// events: on `paused`/`hidden`/`inactive` it emits the locked state (which
/// mounts the `BiometricShieldScreen` overlay) whenever biometric lock is
/// enabled and no authentication dialog is active; on `resumed` it first
/// re-verifies the `Isar` instance — the auto-reopen clears dead query
/// streams — and the shield then runs the biometric authentication flow to
/// unlock the app.
class BiometricLockObserver with WidgetsBindingObserver {
  final bool Function() isBiometricLockEnabled;

  final bool Function()? isAppLocked;

  /// Passes `true` if locked, `false` if unlocked.
  final ValueChanged<bool> onLockStateChanged;

  final Stream<bool>? lockEnabledStream;

  /// Resolves the localized reason shown in the biometric auth prompt.
  final String Function() localizedReason;

  /// Invoked after app resumption when the database was reopened, so consumers can re-subscribe to Isar streams.
  final Future<void> Function()? onDatabaseReopened;

  final Future<({bool reopened})> Function() verifyDatabaseIntegrity;

  bool _isLockEnabled = false;
  bool _disposed = false;
  StreamSubscription<bool>? _subscription;

  /// [localizedReason] is resolved lazily at authentication time so it always
  /// reflects the active locale.
  BiometricLockObserver({
    required this.isBiometricLockEnabled,
    required this.onLockStateChanged,
    required this.localizedReason,
    this.isAppLocked,
    this.lockEnabledStream,
    this.onDatabaseReopened,
    required this.verifyDatabaseIntegrity,
  }) {
    _isLockEnabled = isBiometricLockEnabled();
    WidgetsBinding.instance.addObserver(this);
    _subscription = lockEnabledStream?.listen((enabled) {
      _isLockEnabled = enabled;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      _verifyDatabaseIntegrity();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _checkBiometricLock();
    }
  }

  Future<void> _verifyDatabaseIntegrity() async {
    try {
      final result = await verifyDatabaseIntegrity();
      if (result.reopened) {
        await onDatabaseReopened?.call();
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason:
            '[BiometricLockObserver] Database integrity check on resumption failed',
        fatal: false,
      );
    }
  }

  Future<void> _checkBiometricLock() async {
    if (!_isLockEnabled) return;

    // Do not re-trigger lock if an authentication dialog is currently open,
    // just finished, or if the app is already locked behind BiometricShieldScreen.
    if (BiometricService.instance.isAuthenticating) return;
    if (BiometricService.instance.wasAuthenticatingRecently) return;
    if (isAppLocked?.call() == true) return;

    // The app went to the background and should be locked.
    // We do NOT call authenticate() here, because BiometricShieldScreen will
    // automatically mount when isLocked becomes true, and it handles the auth prompt
    // when the app resumes.
    AppAnalytics.logBiometricBackgroundLocked();
    onLockStateChanged(true);
  }

  /// Safe to call multiple times — subsequent calls are no-ops.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Convenience alias for [dispose].
  void removeThisObserver() => dispose();
}
