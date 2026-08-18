import 'package:balance/core/presentation/utils/picker_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Form widget for Step 5 of the onboarding wizard: scheduling an optional
/// daily reminder notification.
///
/// Persists both choices directly into [AppSettingsBloc] while the user
/// interacts: the daily-enable switch via [ToggleNotifications] and the
/// reminder time via [UpdateNotificationTime]. The step is skippable —
/// [onNext] advances regardless of the switch state — so the wizard screen
/// needs no further persistence on the way out. A permission-denied notice is
/// shown when the OS rejected the notification request.
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
    final initialTime = TimeOfDay(
      hour: recordTime.hour,
      minute: recordTime.minute,
    );

    final picked = await showSafeTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null && context.mounted) {
      context.read<AppSettingsBloc>().add(
        UpdateNotificationTime((hour: picked.hour, minute: picked.minute)),
      );

      AppSnackBar.show(
        context,
        message: l10n.reminderTimeSet(picked.format(context)),
        type: SnackBarType.info,
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
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return ClampedLayout(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: isLandscape ? 8.0 : 24.0,
      ),
      child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
        builder: (context, settingsState) {
          final enabled = settingsState.notificationsEnabled;
          final permissionDenied = settingsState.notificationPermissionDenied;
          final notificationTime = settingsState.notificationTime;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.dailyReminderStepOptionalTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLandscape ? 4.0 : 8.0),
                Text(
                  l10n.dailyReminderStepSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isLandscape ? 8.0 : 20.0),
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
                        Divider(
                          height: 1.0,
                          indent: 16.0,
                          endIndent: 16.0,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        ListTile(
                          key: const Key('notification_step_time_tile'),
                          enabled: enabled,
                          leading: Icon(
                            Icons.access_time,
                            color: enabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.38,
                                  ),
                          ),
                          title: Text(
                            l10n.reminderTime,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            TimeOfDay(
                              hour: notificationTime.hour,
                              minute: notificationTime.minute,
                            ).format(context),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: enabled
                              ? () => _handleTimePicker(context)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
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
                SizedBox(height: isLandscape ? 16.0 : 24.0),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48.0),
                  child: FilledButton(
                    key: const Key('notification_step_next_button'),
                    onPressed: widget.onNext,
                    child: Text(l10n.next),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
