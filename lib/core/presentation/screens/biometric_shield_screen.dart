import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';

import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';

/// The biometric lock overlay and its authentication flow.
///
/// A full-screen lock overlay presented while the app is locked.
///
/// ## Lock lifecycle
/// The shield is expected to be mounted whenever the lock state in
/// [AppSettingsBloc] disables the app UI — typically set by the
/// `BiometricLockObserver` lifecycle observer when the app is backgrounded.
/// On mount it kicks off the biometric authentication flow right after the
/// first frame. A successful authentication clears the lock state and removes
/// the shield; retryable failures keep it mounted and surface a snack bar,
/// while terminal failures (no enrolled credentials, unsupported device,
/// permanent lockout, or missing passcode) offer a lock-recovery dialog that
/// lets the user disable the biometric lock entirely.
class BiometricShieldScreen extends StatefulWidget {
  /// Creates a [BiometricShieldScreen].
  const BiometricShieldScreen({super.key});

  @override
  State<BiometricShieldScreen> createState() => _BiometricShieldScreenState();
}

/// The locked state behind the biometric shield, showing the unlock prompt.
class _BiometricShieldScreenState extends State<BiometricShieldScreen> {
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    AppAnalytics.logBiometricShieldScreenViewed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<AppSettingsBloc>();
        _handleUnlock(context, bloc);
      }
    });
  }

  /// Runs the biometric authentication prompt, unlocks the app on success,
  /// and routes terminal failures to the lock recovery dialog.
  Future<void> _handleUnlock(BuildContext context, AppSettingsBloc bloc) async {
    if (_isUnlocking) return;
    _isUnlocking = true;
    final l10n = AppLocalizations.of(context);

    try {
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
        authMessages: BiometricService.createAuthMessages(l10n),
      );
      if (result == BiometricAuthResult.success) {
        AppAnalytics.logBiometricShieldUnlockSuccess();
        bloc.add(const SetLocked(false));
      } else if (BiometricService.isTerminalFailure(result) ||
          result == BiometricAuthResult.notAvailable) {
        AppAnalytics.logBiometricShieldUnlockFailed(result.name);
        if (!context.mounted) return;
        await _offerLockRecovery(context, bloc, l10n);
      } else {
        AppAnalytics.logBiometricShieldUnlockFailed(result.name);
        if (!bloc.state.isLocked) {
          bloc.add(const SetLocked(true));
        }
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricAuthFailed,
            type: SnackBarType.error,
          );
        }
      }
    } catch (e, stack) {
      AppAnalytics.logBiometricShieldUnlockFailed(e.toString());
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Authentication threw in BiometricShieldScreen',
        fatal: false,
      );
      if (!bloc.state.isLocked) {
        bloc.add(const SetLocked(true));
      }
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.biometricAuthFailed,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
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
    AppAnalytics.logDialogLockRecoveryOpened('biometric_lockout');
    if (!context.mounted) return;
    final disable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(l10n.biometricLockoutTitle),
        content: SizedBox(width: 320, child: Text(l10n.biometricLockoutBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.keepLocked),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.disableLock),
          ),
        ],
      ),
    );
    if (disable == true) {
      AppAnalytics.logDialogLockRecoveryConfirmed();
      bloc.add(const UpdateBiometricLock(false));
      bloc.add(const SetLocked(false));
    } else {
      AppAnalytics.logDialogLockRecoveryCancelled();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.appLocked,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
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
                  Semantics(
                    button: true,
                    enabled: !_isUnlocking,
                    label: l10n.unlock,
                    hint: l10n.biometricAuthReason,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _isUnlocking
                          ? null
                          : () {
                              AppAnalytics.logBiometricShieldUnlockTapped();
                              _handleUnlock(context, bloc);
                            },
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.unlock),
                    ),
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
