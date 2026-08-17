import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Optional onboarding step that lets new users connect Apple Health /
/// Google Health Connect so weight measurements sync automatically.
///
/// The step is skippable by design: the user simply presses the next action
/// without enabling the sync switch. Enabling the switch triggers the native
/// permission request through [AppSettingsBloc]; the wizard advances via the
///// next action once the choice is made.
class StepHealthSync extends StatefulWidget {
  /// Callback invoked when the user proceeds to the next step.
  final VoidCallback onNext;

  /// Creates a [StepHealthSync] widget.
  ///
  /// @param onNext Callback invoked when the user proceeds to the next step.
  const StepHealthSync({super.key, required this.onNext});

  @override
  State<StepHealthSync> createState() => _StepHealthSyncState();
}

class _StepHealthSyncState extends State<StepHealthSync> {
  /// Whether the last permission request was denied. Held in local state
  /// because the transient [AppSettingsState.healthPermissionDenied] flag is
  /// reset immediately after each denial to keep repeated denials observable;
  /// a BlocBuilder would therefore never render it.
  bool _permissionDenied = false;

  /// Dispatches the sync toggle to [AppSettingsBloc]; enabling triggers the
  /// native permission request whose outcome (enabled, denied, or unavailable)
  /// is surfaced reactively via the bloc state.
  void _handleToggle(bool enabled) {
    context.read<AppSettingsBloc>().add(ToggleHealthSync(enabled));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: BlocListener<AppSettingsBloc, AppSettingsState>(
        // Edge-triggered on the transient denial flag: the bloc resets the
        // flag immediately after each denial, so only the transition is
        // observable here.
        listenWhen: (previous, current) =>
            !previous.healthPermissionDenied && current.healthPermissionDenied,
        listener: (context, state) {
          if (!_permissionDenied) {
            setState(() => _permissionDenied = true);
          }
        },
        child: BlocListener<AppSettingsBloc, AppSettingsState>(
          // Clears the denial warning once sync actually becomes active.
          listenWhen: (previous, current) =>
              !previous.isHealthSyncEnabled && current.isHealthSyncEnabled,
          listener: (context, state) {
            if (_permissionDenied) {
              setState(() => _permissionDenied = false);
            }
          },
          child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
            builder: (context, settingsState) {
              final enabled = settingsState.isHealthSyncEnabled;
              final apiAvailable = settingsState.isHealthApiAvailable;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.healthSyncStepOptionalTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    Platform.isIOS
                        ? l10n.healthSyncDescriptionIOS
                        : l10n.healthSyncDescriptionAndroid,
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
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: SwitchListTile(
                        key: const Key('health_sync_step_switch'),
                        value: enabled,
                        onChanged: _handleToggle,
                        title: Text(
                          l10n.healthSync,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          apiAvailable
                              ? (Platform.isIOS
                                    ? l10n.healthSyncTileSubtitleIOS
                                    : l10n.healthSyncTileSubtitleAndroid)
                              : l10n.healthSyncUnavailable,
                        ),
                        secondary: Icon(
                          Icons.monitor_heart_outlined,
                          color: enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (_permissionDenied) ...[
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
                              l10n.healthPermissionDenied,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: FilledButton(
                      key: const Key('health_sync_step_next_button'),
                      onPressed: widget.onNext,
                      child: Text(l10n.next),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
