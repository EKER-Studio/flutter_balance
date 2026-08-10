import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/presentation/core/clamped_layout.dart';

/// Form widget for Step 4 of the onboarding wizard: setting up daily reminder notifications.
class StepReminderNotification extends StatefulWidget {
  /// Callback invoked when proceeding to the next step.
  final VoidCallback onNext;

  /// Creates a [StepReminderNotification] widget.
  const StepReminderNotification({super.key, required this.onNext});

  @override
  State<StepReminderNotification> createState() =>
      _StepReminderNotificationState();
}

class _StepReminderNotificationState extends State<StepReminderNotification> {
  /// Opens the time picker and dispatches the selected time to [AppSettingsBloc].
  Future<void> _handleTimePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final recordTime = context.read<AppSettingsBloc>().state.notificationTime;
    final initialTime = TimeOfDay(hour: recordTime.hour, minute: recordTime.minute);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<AppSettingsBloc>().add(UpdateNotificationTime((hour: picked.hour, minute: picked.minute)));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reminderTimeSet(picked.format(context))),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Toggles the notification permission and dispatches the event to [AppSettingsBloc].
  Future<void> _handleToggle(BuildContext context, bool enabled) async {
    context.read<AppSettingsBloc>().add(ToggleNotifications(enabled));
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
          final permissionDenied = settingsState.notificationPermissionDenied;
          final notificationTime = settingsState.notificationTime;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                l10n.dailyReminderStepOptionalTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              // Subtitle
              Text(
                l10n.dailyReminderStepSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24.0),
              // Notification toggle card
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.0),
                clipBehavior: Clip.antiAlias,
                child: Container(
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
                          Icons.notifications,
                          color: enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Reminder Time row (visible/enabled only when notifications are ON)
              if (enabled) ...[
                const SizedBox(height: 16.0),
                Material(
                  key: const Key('notification_step_time_tile'),
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16.0),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () => _handleTimePicker(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize
                                    .min, // Fix: Prevents layout crash inside Row
                                children: [
                                  Text(
                                    l10n.reminderTime,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    TimeOfDay(hour: notificationTime.hour, minute: notificationTime.minute).format(context),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Permission denied warning
              if (permissionDenied) ...[
                const SizedBox(height: 12.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          l10n.notificationPermissionDenied,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Bottom buttons
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48.0),
                child: FilledButton(
                  key: const Key('notification_step_next_button'),
                  onPressed: widget.onNext,
                  child: Text(l10n.next),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
