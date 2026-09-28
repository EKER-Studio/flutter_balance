import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_toggle.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget displaying the combined privacy and security settings group.
///
/// The biometric lock toggle is shown first when the device supports it,
/// followed by the telemetry opt-ins (usage analytics and crash reports).
/// Telemetry toggles are opt-in and off by default; enabling them takes
/// effect immediately without an app restart.
class PrivacySecuritySection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final Future<bool> isBiometricAvailable;
  final ValueChanged<bool> onBiometricChanged;
  final String biometricsAvailableLabel;
  final String biometricsNotAvailableLabel;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onCrashReportingChanged;

  const PrivacySecuritySection({
    super.key,
    required this.state,
    required this.l10n,
    required this.isBiometricAvailable,
    required this.onBiometricChanged,
    required this.biometricsAvailableLabel,
    required this.biometricsNotAvailableLabel,
    required this.onAnalyticsChanged,
    required this.onCrashReportingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (state.isBiometricSupported)
            FutureBuilder<bool>(
              future: isBiometricAvailable,
              builder: (context, snapshot) {
                final available = snapshot.data ?? false;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                return CustomSettingsToggle(
                  icon: Icons.fingerprint,
                  title: l10n.biometricLock,
                  subtitle: available
                      ? biometricsAvailableLabel
                      : biometricsNotAvailableLabel,
                  sectionLabel: l10n.privacySecuritySection,
                  value: available ? state.isBiometricLockEnabled : false,
                  onChanged: isLoading
                      ? null
                      : (available ? onBiometricChanged : null),
                );
              },
            ),
          CustomSettingsToggle(
            icon: Icons.query_stats_outlined,
            title: l10n.analyticsToggle,
            subtitle: l10n.analyticsToggleDesc,
            sectionLabel: l10n.privacySecuritySection,
            value: state.analyticsEnabled,
            onChanged: onAnalyticsChanged,
          ),
          CustomSettingsToggle(
            icon: Icons.bug_report_outlined,
            title: l10n.crashToggle,
            subtitle: l10n.crashToggleDesc,
            sectionLabel: l10n.privacySecuritySection,
            value: state.crashReportingEnabled,
            onChanged: onCrashReportingChanged,
          ),
        ],
      ),
    );
  }
}
