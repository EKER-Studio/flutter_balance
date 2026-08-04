import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Form widget for Step 3 of the onboarding wizard: setting optional daily reminders.
class StepReminderNotification extends StatelessWidget {
  /// Callback invoked when proceeding to the next step (or skipping).
  final VoidCallback onNext;

  /// Creates a [StepReminderNotification] widget.
  const StepReminderNotification({
    super.key,
    required this.onNext,
  });

  Future<void> _handleToggle(BuildContext context, bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AppSettingsBloc>();

    if (enabled) {
      final status = await Permission.notification.request();
      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {
        bloc.add(const ToggleNotifications(false));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.notificationsDisabledOs),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: l10n.openSettings,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    }

    bloc.add(ToggleNotifications(enabled));
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay initialTime) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null && context.mounted) {
      context.read<AppSettingsBloc>().add(UpdateNotificationTime(newTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          final enabled = settingsState.notificationsEnabled;
          final time = settingsState.notificationTime;
          final formattedTime = time.format(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.dailyReminderStepTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                l10n.dailyReminderStepSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24.0),
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.0),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('notification_step_switch'),
                        value: enabled,
                        onChanged: (val) => _handleToggle(context, val),
                        title: Text(
                          l10n.dailyReminder,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(l10n.dailyReminderDesc),
                        secondary: Icon(
                          enabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          color: enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (enabled) ...[
                        const Divider(height: 1.0),
                        ListTile(
                          key: const Key('notification_step_time_tile'),
                          leading: Icon(
                            Icons.access_time_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(l10n.reminderTime),
                          trailing: OutlinedButton.icon(
                            key: const Key('notification_step_time_button'),
                            onPressed: () => _pickTime(context, time),
                            icon: const ExcludeSemantics(
                              child: Icon(Icons.edit_calendar_outlined, size: 18),
                            ),
                            label: Text(formattedTime),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: TextButton(
                        key: const Key('notification_step_skip_button'),
                        onPressed: onNext,
                        child: Text(l10n.skip),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: FilledButton(
                        key: const Key('notification_step_next_button'),
                        onPressed: onNext,
                        child: Text(l10n.next),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
