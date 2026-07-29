import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';

/// Full-screen overlay shown when the app is locked due to a failed
/// biometric authentication attempt.
class BiometricShieldScreen extends StatelessWidget {
  /// Creates a [BiometricShieldScreen].
  const BiometricShieldScreen({super.key});

  Future<void> _handleUnlock(BuildContext context, AppSettingsBloc bloc) async {
    try {
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
      final l10n = AppLocalizations.of(context);
      final authenticated = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
      );
      if (authenticated) {
        bloc.add(const SetLocked(false));
      } else {
        if (!bloc.state.isLocked) {
          bloc.add(const SetLocked(true));
        }
      }
    } catch (e, stack) {
      debugPrint('[BiometricShieldScreen] Authentication threw: $e\n$stack');
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AppSettingsBloc>();
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appLocked,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.biometricAuthReason,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => _handleUnlock(context, bloc),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.unlock),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
