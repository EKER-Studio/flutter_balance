import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_weight/core/services/biometric_service.dart';

/// Lifecycle observer that enforces biometric lock when the app resumes.
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
  StreamSubscription<bool>? _subscription;

  /// Creates a [BiometricLockObserver] and registers it as a WidgetsBinding observer.
  BiometricLockObserver({
    required this.isBiometricLockEnabled,
    required this.onLockStateChanged,
    this.lockEnabledStream,
    this.localizedReason = 'Authenticate to access PureWeight',
  }) {
    WidgetsBinding.instance.addObserver(this);
    _isLockEnabled = isBiometricLockEnabled();
    _subscription = lockEnabledStream?.listen((enabled) {
      _isLockEnabled = enabled;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
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
        debugPrint(
          '[BiometricLockObserver] Authentication returned false — locking app.',
        );
        onLockStateChanged(true);
      }
    } catch (e, stack) {
      debugPrint('[BiometricLockObserver] Authentication threw: $e\n$stack');
      onLockStateChanged(true);
    }
  }

  /// Disposes this observer and cancels the settings stream subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Removes this observer and cancels the settings stream subscription.
  void removeThisObserver() => dispose();
}
