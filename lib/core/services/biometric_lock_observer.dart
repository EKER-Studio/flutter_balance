import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/biometric_service.dart';

/// Lifecycle observer that enforces biometric lock and verifies database integrity when the app resumes.
class BiometricLockObserver with WidgetsBindingObserver {
  /// Callback returning whether biometric lock is enabled.
  final bool Function() isBiometricLockEnabled;

  /// Optional callback returning whether the app is currently locked.
  final bool Function()? isAppLocked;

  /// Callback emitted when the lock state changes (true = locked, false = unlocked).
  final ValueChanged<bool> onLockStateChanged;

  /// Optional stream emitting changes to the biometric lock enabled setting.
  final Stream<bool>? lockEnabledStream;

  /// Resolves the localized reason shown in the biometric auth prompt.
  final String Function() localizedReason;

  /// Optional callback invoked when the database had to be reopened after
  /// app resumption, so consumers can re-subscribe to Isar streams.
  final Future<void> Function()? onDatabaseReopened;

  bool _isLockEnabled = false;
  bool _disposed = false;
  StreamSubscription<bool>? _subscription;

  /// Creates a [BiometricLockObserver] and registers it as a WidgetsBinding observer.
  ///
  /// [localizedReason] is resolved lazily at authentication time so it always
  /// reflects the active locale.
  BiometricLockObserver({
    required this.isBiometricLockEnabled,
    required this.onLockStateChanged,
    required this.localizedReason,
    this.isAppLocked,
    this.lockEnabledStream,
    this.onDatabaseReopened,
  }) {
    _isLockEnabled = isBiometricLockEnabled();
    WidgetsBinding.instance.addObserver(this);
    _subscription = lockEnabledStream?.listen((enabled) {
      _isLockEnabled = enabled;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyDatabaseIntegrity();
      _checkBiometricLock();
    }
  }

  Future<void> _verifyDatabaseIntegrity() async {
    try {
      final result = await DatabaseModule.ensureInstanceIntegrity();
      if (result.reopened) {
        await onDatabaseReopened?.call();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[BiometricLockObserver] Database integrity check on resumption failed: $e\n$stack',
        );
      }
    }
  }

  Future<void> _checkBiometricLock() async {
    if (!_isLockEnabled) return;

    // Do not re-trigger lock if an authentication dialog is currently open,
    // just finished, or if the app is already locked behind BiometricShieldScreen.
    if (BiometricService.instance.isAuthenticating) return;
    if (BiometricService.instance.wasAuthenticatingRecently) return;
    if (isAppLocked?.call() == true) return;

    // Wait until current frame ends so FlutterFragmentActivity is attached & resumed natively
    await WidgetsBinding.instance.endOfFrame;

    final isAvailable = await BiometricService.instance.isAvailable();
    if (!isAvailable) return;

    // The app came from the background and should be locked.
    // We do NOT call authenticate() here, because BiometricShieldScreen will
    // automatically mount when isLocked becomes true, and it handles the auth prompt.
    onLockStateChanged(true);
  }

  /// Disposes this observer and cancels the settings stream subscription.
  /// Safe to call multiple times — subsequent calls are no-ops.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Removes this observer and cancels the settings stream subscription.
  /// Convenience alias for [dispose].
  void removeThisObserver() => dispose();
}
