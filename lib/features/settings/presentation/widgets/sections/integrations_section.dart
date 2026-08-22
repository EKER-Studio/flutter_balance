import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/utils/health_service_platform_localizer.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_tile.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_toggle.dart';

/// A widget that displays the integrations settings group with the health sync switch.
class IntegrationsSection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final ValueChanged<bool> onHealthSyncChanged;

  /// Callback invoked when the tile asks to install Health Connect (Android only).
  final VoidCallback onInstallHealthConnect;

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
    final platform = Theme.of(context).platform;
    final isAndroid = platform == TargetPlatform.android;
    final showInstallAction = !apiAvailable && isAndroid;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: showInstallAction
          ? CustomSettingsTile(
              icon: Icons.monitor_heart_outlined,
              title: platform.healthServiceName(l10n),
              subtitle: l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              onTap: onInstallHealthConnect,
            )
          : CustomSettingsToggle(
              icon: Icons.monitor_heart_outlined,
              title: platform.healthServiceName(l10n),
              subtitle: apiAvailable
                  ? platform.healthServiceSyncDescription(l10n)
                  : l10n.healthSyncUnavailable,
              sectionLabel: l10n.integrationsSection,
              value: state.isHealthSyncEnabled,
              onChanged: apiAvailable ? onHealthSyncChanged : null,
            ),
    );
  }
}
