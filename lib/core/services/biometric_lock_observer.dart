import 'package:flutter/material.dart';


import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';


import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

/// Lifecycle observer that enforces biometric lock when the app resumes.
class BiometricLockObserver with WidgetsBindingObserver {
  /// The [AppSettingsBloc] used to read current settings state.
  final AppSettingsBloc settingsBloc;

  /// Localized reason displayed in the biometric auth dialog.
  final String localizedReason;

  /// Creates a [BiometricLockObserver] and registers it as a WidgetsBinding observer.
  BiometricLockObserver({
    required this.settingsBloc,
    this.localizedReason = 'Authenticate to access PureWeight',
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    if (!settingsBloc.state.isBiometricLockEnabled) return;

    final isAvailable = await BiometricService.instance.isAvailable();
    if (!isAvailable) return;

    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: localizedReason,
      );

      if (authenticated) {
        settingsBloc.add(const SetLocked(false));
      } else {
        debugPrint(
          '[BiometricLockObserver] Authentication returned false — locking app.',
        );
        settingsBloc.add(const SetLocked(true));
      }
    } catch (e, stack) {
      debugPrint('[BiometricLockObserver] Authentication threw: $e\n$stack');
      settingsBloc.add(const SetLocked(true));
    }
  }

  /// Removes this observer.
  void removeThisObserver() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
