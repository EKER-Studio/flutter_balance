// Application settings group: measurement unit, theme and daily reminder controls.

import 'package:flutter/material.dart';
import 'package:balance/core/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'custom_settings_tile.dart';
import 'custom_settings_toggle.dart';

/// A widget that represents the application settings group.
class ApplicationSection extends StatelessWidget {
  final AppSettingsState state;
  final AppLocalizations l10n;
  final VoidCallback onThemeTap;
  final VoidCallback onUnitTap;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onNotificationTimeTap;

  const ApplicationSection({
    super.key,
    required this.state,
    required this.l10n,
    required this.onThemeTap,
    required this.onUnitTap,
    required this.onNotificationsChanged,
    required this.onNotificationTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeLabel = state.themeMode.localizedName(l10n);
    final unitLabel = state.measurementUnit.localizedName(l10n);
    final notificationTimeText = TimeOfDay(
      hour: state.notificationTime.hour,
      minute: state.notificationTime.minute,
    ).format(context);

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.straighten,
            title: l10n.measurementUnit,
            subtitle: unitLabel,
            sectionLabel: l10n.applicationSection,
            onTap: () {
              AppAnalytics.logSettingsUnitTileClicked(
                state.measurementUnit.name,
              );
              onUnitTap();
            },
          ),
          CustomSettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            subtitle: themeLabel,
            sectionLabel: l10n.applicationSection,
            onTap: () {
              AppAnalytics.logSettingsThemeTileClicked(state.themeMode.name);
              onThemeTap();
            },
          ),
          CustomSettingsToggle(
            icon: Icons.notifications_outlined,
            title: l10n.dailyReminder,
            subtitle: l10n.dailyReminderDesc,
            sectionLabel: l10n.applicationSection,
            value: state.notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          if (state.notificationsEnabled)
            CustomSettingsTile(
              icon: Icons.access_time_outlined,
              title: l10n.reminderTime,
              subtitle: notificationTimeText,
              sectionLabel: l10n.applicationSection,
              onTap: () {
                AppAnalytics.logSettingsReminderTimeTileClicked(
                  notificationTimeText,
                );
                onNotificationTimeTap();
              },
            ),
        ],
      ),
    );
  }
}
