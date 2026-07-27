import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

/// Full-screen overlay shown when the app is locked due to a failed
/// biometric authentication attempt.
class BiometricShieldScreen extends StatelessWidget {
  /// Creates a [BiometricShieldScreen].
  const BiometricShieldScreen({super.key});

  Future<void> _handleUnlock(AppSettingsBloc bloc) async {
    try {
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: 'Authenticate to access PureWeight',
      );
      if (authenticated) {
        bloc.add(const SetLocked(false));
      }
    } catch (e, stack) {
      debugPrint('[BiometricShieldScreen] Authentication threw: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AppSettingsBloc>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'App Locked',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Authenticate to access PureWeight',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _handleUnlock(bloc),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
