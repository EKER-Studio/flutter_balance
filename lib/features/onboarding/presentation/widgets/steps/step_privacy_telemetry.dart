import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Form widget for the optional privacy and diagnostics step of the onboarding wizard.
///
/// Provides opt-in controls for anonymous usage analytics and anonymous crash reports.
/// The step is skippable — [onNext] advances regardless of the toggle states.
class StepPrivacyTelemetry extends StatelessWidget {
  /// Callback invoked when proceeding to the next step.
  final VoidCallback onNext;

  const StepPrivacyTelemetry({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settingsState) {
        final analyticsEnabled = settingsState.analyticsEnabled;
        final crashReportingEnabled = settingsState.crashReportingEnabled;

        return OnboardingStepLayout(
          title: l10n.privacyTelemetryStepOptionalTitle,
          subtitle: l10n.privacyTelemetryStepSubtitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('privacy_step_analytics_switch'),
                        value: analyticsEnabled,
                        onChanged: (val) {
                          context.read<AppSettingsBloc>().add(
                            ToggleAnalytics(val),
                          );
                        },
                        title: Text(
                          l10n.analyticsToggle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(l10n.analyticsToggleDesc),
                        secondary: Icon(
                          Icons.query_stats_outlined,
                          color: analyticsEnabled
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
                      SwitchListTile(
                        key: const Key('privacy_step_crash_reports_switch'),
                        value: crashReportingEnabled,
                        onChanged: (val) {
                          context.read<AppSettingsBloc>().add(
                            ToggleCrashReporting(val),
                          );
                        },
                        title: Text(
                          l10n.crashToggle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(l10n.crashToggleDesc),
                        secondary: Icon(
                          Icons.bug_report_outlined,
                          color: crashReportingEnabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          footer: FilledButton(
            key: const Key('privacy_step_next_button'),
            onPressed: onNext,
            child: Text(l10n.next),
          ),
        );
      },
    );
  }
}
