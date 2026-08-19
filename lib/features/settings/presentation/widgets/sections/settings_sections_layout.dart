import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/application_section.dart';
import 'package:balance/features/settings/presentation/widgets/data_section.dart';
import 'package:balance/features/settings/presentation/widgets/help_section.dart';
import 'package:balance/features/settings/presentation/widgets/integrations_section.dart';
import 'package:balance/features/settings/presentation/widgets/profile_section.dart';
import 'package:balance/features/settings/presentation/widgets/section_header.dart';
import 'package:balance/features/settings/presentation/widgets/security_section.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A responsive layout section that arranges settings sections in two columns on wide viewports or a single column on mobile.
class SettingsSectionsLayout extends StatelessWidget {
  /// The current app settings state.
  final AppSettingsState state;

  /// Resolves to whether biometric authentication is available on device.
  final Future<bool> isBiometricAvailable;

  /// Callback to show the height configuration dialog.
  final VoidCallback onHeightTap;

  /// Callback to show the target weight dialog.
  final VoidCallback onTargetWeightTap;

  /// Callback to show the theme selection dialog.
  final VoidCallback onThemeTap;

  /// Callback to show the unit selection dialog.
  final VoidCallback onUnitTap;

  /// Callback when notification toggle value changes.
  final ValueChanged<bool> onNotificationsChanged;

  /// Callback to pick the reminder notification time.
  final VoidCallback onNotificationTimeTap;

  /// Callback when health sync toggle value changes.
  final ValueChanged<bool> onHealthSyncChanged;

  /// Callback to trigger Health Connect installation on Android.
  final VoidCallback onInstallHealthConnect;

  /// Callback when biometric lock toggle value changes.
  final ValueChanged<bool> onBiometricChanged;

  /// Callback to initiate CSV import.
  final VoidCallback onImportTap;

  /// Callback to initiate CSV export.
  final VoidCallback onExportTap;

  /// Callback to show wipe database confirmation dialog.
  final VoidCallback onWipeTap;

  /// Callback to send crash logs.
  final VoidCallback onCrashLogTap;

  /// Creates a [SettingsSectionsLayout] widget.
  const SettingsSectionsLayout({
    super.key,
    required this.state,
    required this.isBiometricAvailable,
    required this.onHeightTap,
    required this.onTargetWeightTap,
    required this.onThemeTap,
    required this.onUnitTap,
    required this.onNotificationsChanged,
    required this.onNotificationTimeTap,
    required this.onHealthSyncChanged,
    required this.onInstallHealthConnect,
    required this.onBiometricChanged,
    required this.onImportTap,
    required this.onExportTap,
    required this.onWipeTap,
    required this.onCrashLogTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final maxContentWidth = isWide ? 900.0 : 600.0;
        final horizontalPadding = isWide ? 24.0 : 16.0;

        final profileHeader = SectionHeader(label: l10n.profileSection);
        final profileSection = ProfileSection(
          state: state,
          l10n: l10n,
          onHeightTap: onHeightTap,
          onTargetWeightTap: onTargetWeightTap,
        );

        final applicationHeader = SectionHeader(label: l10n.applicationSection);
        final applicationSection = ApplicationSection(
          state: state,
          l10n: l10n,
          onThemeTap: onThemeTap,
          onUnitTap: onUnitTap,
          onNotificationsChanged: onNotificationsChanged,
          onNotificationTimeTap: onNotificationTimeTap,
        );

        final integrationsHeader = SectionHeader(
          label: l10n.integrationsSection,
        );
        final integrationsSection = IntegrationsSection(
          state: state,
          l10n: l10n,
          onHealthSyncChanged: onHealthSyncChanged,
          onInstallHealthConnect: onInstallHealthConnect,
        );

        final securityHeader = SectionHeader(label: l10n.securitySection);
        final securitySection = SecuritySection(
          state: state,
          l10n: l10n,
          isBiometricAvailable: isBiometricAvailable,
          onBiometricChanged: onBiometricChanged,
          biometricsAvailableLabel: l10n.biometricDesc,
          biometricsNotAvailableLabel: l10n.biometricsNotAvailable,
        );

        final dataHeader = SectionHeader(label: l10n.dataSection);
        final dataSection = DataSection(
          l10n: l10n,
          onImportTap: onImportTap,
          onExportTap: onExportTap,
          onWipeTap: onWipeTap,
        );

        final helpHeader = SectionHeader(label: l10n.helpSection);
        final helpSection = HelpSection(
          l10n: l10n,
          onCrashLogTap: onCrashLogTap,
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    l10n.settingsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileHeader,
                              const SizedBox(height: 8),
                              profileSection,
                              const SizedBox(height: 24),
                              applicationHeader,
                              const SizedBox(height: 8),
                              applicationSection,
                              const SizedBox(height: 24),
                              integrationsHeader,
                              const SizedBox(height: 8),
                              integrationsSection,
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.isBiometricSupported) ...[
                                securityHeader,
                                const SizedBox(height: 8),
                                securitySection,
                                const SizedBox(height: 24),
                              ],
                              dataHeader,
                              const SizedBox(height: 8),
                              dataSection,
                              const SizedBox(height: 24),
                              helpHeader,
                              const SizedBox(height: 8),
                              helpSection,
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileHeader,
                        const SizedBox(height: 8),
                        profileSection,
                        const SizedBox(height: 16),
                        applicationHeader,
                        const SizedBox(height: 8),
                        applicationSection,
                        const SizedBox(height: 16),
                        integrationsHeader,
                        const SizedBox(height: 8),
                        integrationsSection,
                        const SizedBox(height: 16),
                        if (state.isBiometricSupported) ...[
                          securityHeader,
                          const SizedBox(height: 8),
                          securitySection,
                          const SizedBox(height: 16),
                        ],
                        dataHeader,
                        const SizedBox(height: 8),
                        dataSection,
                        const SizedBox(height: 16),
                        helpHeader,
                        const SizedBox(height: 8),
                        helpSection,
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
