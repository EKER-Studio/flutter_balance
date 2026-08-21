import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'custom_settings_toggle.dart';

/// A widget that represents the security settings group with the biometric lock switch.
class SecuritySection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final Future<bool> isBiometricAvailable;
  final ValueChanged<bool> onBiometricChanged;
  final String biometricsAvailableLabel;
  final String biometricsNotAvailableLabel;

  const SecuritySection({
    super.key,
    required this.state,
    required this.l10n,
    required this.isBiometricAvailable,
    required this.onBiometricChanged,
    required this.biometricsAvailableLabel,
    required this.biometricsNotAvailableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<bool>(
        future: isBiometricAvailable,
        builder: (context, snapshot) {
          final available = snapshot.data ?? false;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return CustomSettingsToggle(
            icon: Icons.fingerprint,
            title: l10n.biometricLock,
            subtitle: available
                ? biometricsAvailableLabel
                : biometricsNotAvailableLabel,
            sectionLabel: l10n.securitySection,
            value: available ? state.isBiometricLockEnabled : false,
            onChanged: isLoading
                ? null
                : (available ? onBiometricChanged : null),
          );
        },
      ),
    );
  }
}
