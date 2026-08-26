import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/utils/health_service_platform_localizer.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';

/// Optional onboarding step that lets new users connect Apple Health /
/// Google Health Connect so weight measurements sync automatically.
///
/// The step is skippable by design: the user simply presses the next action
/// without enabling the sync switch. Enabling the switch triggers the native
/// permission request flow, updating [AppSettingsBloc] on success; denying
/// permission shows an inline warning and keeps the switch off.
class StepHealthSync extends StatefulWidget {
  final VoidCallback onNext;

  const StepHealthSync({super.key, required this.onNext});

  @override
  State<StepHealthSync> createState() => _StepHealthSyncState();
}

class _StepHealthSyncState extends State<StepHealthSync> {
  bool _permissionDenied = false;

  void _handleToggle(bool enabled) {
    AppAnalytics.logOnboardingHealthSyncToggleClicked(enabled);
    context.read<AppSettingsBloc>().add(ToggleHealthSync(enabled));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final platform = Theme.of(context).platform;

    return BlocListener<AppSettingsBloc, AppSettingsState>(
      listenWhen: (previous, current) =>
          !previous.healthPermissionDenied && current.healthPermissionDenied,
      listener: (context, state) {
        AppAnalytics.logOnboardingHealthSyncToggled(
          enabled: false,
          permissionGranted: false,
        );
        if (!_permissionDenied) {
          setState(() => _permissionDenied = true);
        }
      },
      child: BlocListener<AppSettingsBloc, AppSettingsState>(
        listenWhen: (previous, current) =>
            !previous.isHealthSyncEnabled && current.isHealthSyncEnabled,
        listener: (context, state) {
          AppAnalytics.logOnboardingHealthSyncToggled(
            enabled: true,
            permissionGranted: true,
          );
          if (_permissionDenied) {
            setState(() => _permissionDenied = false);
          }
        },
        child: BlocBuilder<AppSettingsBloc, AppSettingsState>(
          builder: (context, settingsState) {
            final enabled = settingsState.isHealthSyncEnabled;
            final apiAvailable = settingsState.isHealthApiAvailable;

            return OnboardingStepLayout(
              title: l10n.healthSyncStepOptionalTitle,
              subtitle: platform == TargetPlatform.iOS
                  ? l10n.healthSyncDescriptionIOS
                  : l10n.healthSyncDescriptionAndroid,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                    clipBehavior: Clip.antiAlias,
                    child: DecoratedBox(
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
                          platform.healthServiceName(l10n),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          apiAvailable
                              ? (platform == TargetPlatform.iOS
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
                        borderRadius: BorderRadius.circular(16.0),
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
                ],
              ),
              footer: FilledButton(
                key: const Key('health_sync_step_next_button'),
                onPressed: widget.onNext,
                child: Text(l10n.next),
              ),
            );
          },
        ),
      ),
    );
  }
}
