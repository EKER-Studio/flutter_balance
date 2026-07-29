import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pure_weight/core/database/database_module.dart';
import 'package:pure_weight/core/services/biometric_service.dart';

/// Lifecycle observer that enforces biometric lock and verifies database integrity when the app resumes.
class BiometricLockObserver with WidgetsBindingObserver {
  /// Callback returning whether biometric lock is enabled.
  final bool Function() isBiometricLockEnabled;

  /// Callback emitted when the lock state changes (true = locked, false = unlocked).
  final ValueChanged<bool> onLockStateChanged;

  /// Optional stream emitting changes to the biometric lock enabled setting.
  final Stream<bool>? lockEnabledStream;

  /// Localized reason displayed in the biometric auth dialog.
  final String localizedReason;

  bool _isLockEnabled = false;
  bool _disposed = false;
  StreamSubscription<bool>? _subscription;

  /// Creates a [BiometricLockObserver] and registers it as a WidgetsBinding observer.
  BiometricLockObserver({
    required this.isBiometricLockEnabled,
    required this.onLockStateChanged,
    this.lockEnabledStream,
    this.localizedReason = 'Authenticate to access PureWeight',
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
      await DatabaseModule.ensureInstanceIntegrity();
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

    final isAvailable = await BiometricService.instance.isAvailable();
    if (!isAvailable) return;

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: localizedReason,
      );

      if (authenticated) {
        onLockStateChanged(false);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BiometricLockObserver] Authentication returned false — locking app.',
          );
        }
        onLockStateChanged(true);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricLockObserver] Authentication threw: $e\n$stack');
      }
      onLockStateChanged(true);
    }
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
