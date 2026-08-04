import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pure_weight/core/services/biometric_service.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';

/// Full-screen overlay shown when the app is locked due to a failed
/// biometric authentication attempt.
class BiometricShieldScreen extends StatefulWidget {
  /// Creates a [BiometricShieldScreen].
  const BiometricShieldScreen({super.key});

  @override
  State<BiometricShieldScreen> createState() => _BiometricShieldScreenState();
}

/// Locked state behind the biometric shield, showing the unlock prompt.
class _BiometricShieldScreenState extends State<BiometricShieldScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<AppSettingsBloc>();
        _handleUnlock(context, bloc);
      }
    });
  }

  Future<void> _handleUnlock(BuildContext context, AppSettingsBloc bloc) async {
    try {
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
      final l10n = AppLocalizations.of(context);
      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
      );
      if (result == BiometricAuthResult.success) {
        bloc.add(const SetLocked(false));
      } else if (BiometricService.isTerminalFailure(result) ||
          result == BiometricAuthResult.notAvailable) {
        if (!context.mounted) return;
        await _offerLockRecovery(context, bloc, l10n);
      } else {
        if (!bloc.state.isLocked) {
          bloc.add(const SetLocked(true));
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.biometricAuthFailed)));
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricShieldScreen] Authentication threw: $e\n$stack');
      }
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
    }
  }

  /// Offers the user a way out of a permanent biometric lockout.
  ///
  /// When authentication is impossible (no enrolled credentials, biometrics
  /// unsupported, permanent lockout), the user may turn the biometric lock off
  /// entirely instead of being stuck behind the shield forever.
  Future<void> _offerLockRecovery(
    BuildContext context,
    AppSettingsBloc bloc,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) return;
    final disable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.biometricLockoutTitle),
        content: Text(l10n.biometricLockoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.keepLocked),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.disableLock),
          ),
        ],
      ),
    );
    if (disable == true) {
      bloc.add(const UpdateBiometricLock(false));
      bloc.add(const SetLocked(false));
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
                  Semantics(
                    label: l10n.appLockedStatusIconSemantics,
                    image: true,
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
