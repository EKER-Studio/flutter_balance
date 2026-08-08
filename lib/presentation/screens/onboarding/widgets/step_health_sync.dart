import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/bloc/settings/app_settings_state.dart';
import 'package:balance/presentation/core/clamped_layout.dart';

/// Optional onboarding step that lets new users connect Apple Health /
/// Google Health Connect so weight measurements sync automatically.
///
/// The step is fully skippable: the user can either press the skip action or
/// connect the platform health API, in which case the wizard advances
/// automatically once the permission request succeeds.
class StepHealthSync extends StatefulWidget {
  /// Callback invoked when health sync is connected and the step advances.
  final VoidCallback onNext;

  /// Callback invoked when the user skips the step without connecting.
  final VoidCallback onSkip;

  /// Creates a [StepHealthSync] widget.
  ///
  /// @param onNext Callback invoked when health sync is connected and the step advances.
  /// @param onSkip Callback invoked when the user skips the step without connecting.
  const StepHealthSync({super.key, required this.onNext, required this.onSkip});

  @override
  State<StepHealthSync> createState() => _StepHealthSyncState();
}

class _StepHealthSyncState extends State<StepHealthSync> {
  /// Whether a delayed advance has already been scheduled for the connected
  /// state, so revisiting the step does not auto-advance twice.
  bool _advanceScheduled = false;

  /// Whether the last permission request was denied. Held in local state
  /// because the transient [AppSettingsState.healthPermissionDenied] flag is
  /// reset immediately after each denial to keep repeated denials observable;
  /// a [BlocBuilder] would therefore never render it.
  bool _permissionDenied = false;

  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  /// Dispatches the enable event to [AppSettingsBloc]; the outcome (enabled,
  /// denied, or unavailable) is surfaced reactively via the bloc state.
  void _handleConnect() {
    context.read<AppSettingsBloc>().add(const ToggleHealthSync(true));
  }

  /// Shows the connected state briefly, then advances to the next step.
  void _scheduleAdvance() {
    if (_advanceScheduled) return;
    _advanceScheduled = true;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onNext();
      }
    });
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
          listenWhen: (previous, current) =>
              !previous.isHealthSyncEnabled && current.isHealthSyncEnabled,
          listener: (context, state) {
            if (_permissionDenied) {
              setState(() => _permissionDenied = false);
            }
            _scheduleAdvance();
          },
          child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
            builder: (context, settingsState) {
              final enabled = settingsState.isHealthSyncEnabled;
              final apiAvailable = settingsState.isHealthApiAvailable;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    l10n.healthSyncStepOptionalTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Subtitle
                  Text(
                    l10n.healthSyncStepSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  if (enabled)
                    _buildConnected(theme, l10n)
                  else
                    _buildConnectCard(theme, l10n, apiAvailable),
                  // Permission denied warning
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
                  if (!enabled) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: FilledButton.icon(
                        key: const Key('health_sync_connect_button'),
                        onPressed: _handleConnect,
                        icon: const Icon(Icons.favorite),
                        label: Text(l10n.healthSyncConnectButton),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextButton(
                      key: const Key('health_sync_skip_button'),
                      onPressed: widget.onSkip,
                      child: Text(l10n.skip),
                    ),
                  ] else
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: FilledButton(
                        key: const Key('health_sync_continue_button'),
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

  /// Builds the connected success view with a checkmark icon.
  Widget _buildConnected(ThemeData theme, AppLocalizations l10n) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
          const SizedBox(height: 16.0),
          Text(
            l10n.healthSyncConnected,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the connect card with the health platform icon and description.
  Widget _buildConnectCard(
    ThemeData theme,
    AppLocalizations l10n,
    bool apiAvailable,
  ) {
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(28.0),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 48,
              color: apiAvailable
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16.0),
            if (!apiAvailable)
              Text(
                l10n.healthSyncUnavailable,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
