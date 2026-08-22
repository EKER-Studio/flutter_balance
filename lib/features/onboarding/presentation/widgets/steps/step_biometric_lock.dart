import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';

/// Form widget for the optional biometric lock step of the onboarding wizard
/// (shown as step 7 when the device supports credentials).
///
/// Enabling the switch authenticates the user via [BiometricService] first
/// and persists the choice to [AppSettingsBloc] only on success; disabling
/// persists immediately. The step is skippable — [onNext] advances regardless
/// of the switch state — and when no credential is available the switch is
/// disabled and a notice is shown instead.
class StepBiometricLock extends StatefulWidget {
  /// Callback invoked when proceeding to the next step (or skipping).
  final VoidCallback onNext;

  const StepBiometricLock({super.key, required this.onNext});

  @override
  State<StepBiometricLock> createState() => _StepBiometricLockState();
}

class _StepBiometricLockState extends State<StepBiometricLock> {
  /// Whether the device exposes credentials (biometric or OS fallback);
  /// defaults to `true` so the switch stays enabled until the async check
  /// completes.
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  /// Resolves device credential availability (biometric or OS PIN/pattern/
  /// password fallback) for the switch state.
  Future<void> _checkBiometrics() async {
    final available = await BiometricService.instance.canAuthenticate();
    if (mounted) {
      setState(() {
        _isAvailable = available;
      });
    }
  }

  /// Toggles the biometric lock, authenticating the user before enabling it.
  Future<void> _handleToggle(BuildContext context, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();
    AppAnalytics.logOnboardingBiometricsToggleClicked(enabled);

    if (enabled) {
      final available = await BiometricService.instance.canAuthenticate();
      if (!available) {
        AppAnalytics.logOnboardingBiometricsAuthResult(false);
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricsNotAvailable,
            type: SnackBarType.error,
          );
        }
        return;
      }

      final result = await BiometricService.instance.authenticate(
        localizedReason: l10n.biometricAuthReason,
        authMessages: BiometricService.createAuthMessages(l10n),
      );

      final success = result == BiometricAuthResult.success;
      AppAnalytics.logOnboardingBiometricsAuthResult(success);
      if (success) {
        AppAnalytics.logOnboardingBiometricsToggled(true);
        bloc.add(const UpdateBiometricLock(true));
      } else {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.biometricAuthFailed,
            type: SnackBarType.error,
          );
        }
      }
    } else {
      AppAnalytics.logOnboardingBiometricsToggled(false);
      bloc.add(const UpdateBiometricLock(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return ClampedLayout(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: isLandscape ? 8.0 : 24.0,
      ),
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          final enabled = settingsState.isBiometricLockEnabled;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.biometricStepOptionalTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLandscape ? 4.0 : 8.0),
                Text(
                  l10n.biometricStepSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isLandscape ? 8.0 : 20.0),
                Material(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16.0),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          key: const Key('biometric_step_switch'),
                          value: enabled,
                          onChanged: _isAvailable
                              ? (val) => _handleToggle(context, val)
                              : null,
                          title: Text(
                            l10n.biometricLock,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _isAvailable
                                ? l10n.biometricDesc
                                : l10n.biometricsNotAvailable,
                          ),
                          secondary: Icon(
                            Icons.fingerprint,
                            color: enabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isLandscape ? 16.0 : 24.0),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton(
                    key: const Key('biometric_step_next_button'),
                    onPressed: widget.onNext,
                    child: Text(l10n.next),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
