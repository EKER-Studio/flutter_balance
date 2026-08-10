import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'custom_settings_tile.dart';
import 'custom_settings_toggle.dart';
import 'inexact_reminder_hint.dart';

/// Application settings group with unit, theme, and reminder controls.
class ApplicationSection extends StatelessWidget {
  /// The current app settings state driving the displayed values.
  final AppSettingsState state;

  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the theme tile is tapped.
  final VoidCallback onThemeTap;

  /// Callback invoked when the measurement unit tile is tapped.
  final VoidCallback onUnitTap;

  /// Callback invoked when the notifications switch is toggled.
  final ValueChanged<bool> onNotificationsChanged;

  /// Callback invoked when the reminder time tile is tapped.
  final VoidCallback onNotificationTimeTap;

  /// Creates an [ApplicationSection] with the given dependencies.
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.straighten,
            title: l10n.measurementUnit,
            valueText: unitLabel,
            sectionLabel: l10n.applicationSection,
            onTap: onUnitTap,
          ),
          CustomSettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            valueText: themeLabel,
            sectionLabel: l10n.applicationSection,
            onTap: onThemeTap,
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
              valueText: notificationTimeText,
              sectionLabel: l10n.applicationSection,
              onTap: onNotificationTimeTap,
            ),
          if (state.notificationsEnabled && state.notificationInexactScheduling)
            InexactReminderHint(l10n: l10n),
        ],
      ),
    );
  }
}

/// Inline hint shown when the daily reminder falls back to inexact Android
