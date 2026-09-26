import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_toggle.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget displaying the privacy settings group with telemetry opt-ins.
///
/// Both toggles are opt-in and off by default; enabling them takes effect
/// immediately without an app restart.
class PrivacySection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onCrashReportingChanged;

  const PrivacySection({
    super.key,
    required this.state,
    required this.l10n,
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
          CustomSettingsToggle(
            icon: Icons.query_stats_outlined,
            title: l10n.analyticsToggle,
            subtitle: l10n.analyticsToggleDesc,
            sectionLabel: l10n.privacySection,
            value: state.analyticsEnabled,
            onChanged: onAnalyticsChanged,
          ),
          CustomSettingsToggle(
            icon: Icons.bug_report_outlined,
            title: l10n.crashToggle,
            subtitle: l10n.crashToggleDesc,
            sectionLabel: l10n.privacySection,
            value: state.crashReportingEnabled,
            onChanged: onCrashReportingChanged,
          ),
        ],
      ),
    );
  }
}
