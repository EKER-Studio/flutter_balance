// Integrations settings group with the health sync switch.

import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'custom_settings_tile.dart';
import 'custom_settings_toggle.dart';

/// A widget that displays the integrations settings group with the health sync switch.
class IntegrationsSection extends StatelessWidget {
  /// The current app settings [state] driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for the [IntegrationsSection] widget.
  final AppLocalizations l10n;

  /// Callback invoked when the health sync switch is toggled, allowing the app to sync with health services.
  final ValueChanged<bool> onHealthSyncChanged;

  /// Callback invoked when the tile asks to install Health Connect.
  ///
  /// Only invoked on Android when the health API is unavailable.
  final VoidCallback onInstallHealthConnect;

  /// Creates an [IntegrationsSection] with the given dependencies.
  const IntegrationsSection({
    super.key,
    required this.state,
    required this.l10n,
    required this.onHealthSyncChanged,
    required this.onInstallHealthConnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final apiAvailable = state.isHealthApiAvailable;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final showInstallAction = !apiAvailable && isAndroid;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: showInstallAction
          ? CustomSettingsTile(
              icon: Icons.monitor_heart_outlined,
              title: l10n.healthSync,
              subtitle: l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              onTap: onInstallHealthConnect,
            )
          : CustomSettingsToggle(
              icon: Icons.monitor_heart_outlined,
              title: l10n.healthSync,
              subtitle: apiAvailable
                  ? l10n.healthSyncDesc
                  : l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              value: state.isHealthSyncEnabled,
              onChanged: apiAvailable ? onHealthSyncChanged : null,
            ),
    );
  }
}
