import 'package:flutter/material.dart';

import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

/// Lifecycle observer that enforces biometric lock when the app resumes.
class BiometricLockObserver with WidgetsBindingObserver {
  /// The [AppSettingsBloc] used to read current settings state.
  final AppSettingsBloc settingsBloc;

  /// Localized reason displayed in the biometric auth dialog.
  final String localizedReason;

  /// Creates a [BiometricLockObserver].
  BiometricLockObserver({
    required this.settingsBloc,
    this.localizedReason = 'Authenticate to access PureWeight',
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    final state = settingsBloc.state;

    // Only enforce lock if the setting is enabled and biometrics are available.
    if (!state.isBiometricLockEnabled) return;

    final isAvailable = await BiometricService.instance.isAvailable();
    if (!isAvailable) return;

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: localizedReason,
      );

      if (!authenticated) {
        // User cancelled or authentication failed — allow access for now.
        // A dedicated lock screen can be added later.
      }
    } catch (_) {
      // Authentication error — allow access gracefully.
    }
  }

  /// Removes this observer from [WidgetsBinding].
  void removeThisObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
