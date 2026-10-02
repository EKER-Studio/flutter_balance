import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:balance/core/integrations/widgets/widget_sync_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dismissible card promoting the native home-screen widget.
///
/// Shown on the Today screen only when all of the following hold: the
/// platform is Android with pin-request support, no widget instance is
/// currently pinned, and the user has not dismissed the card before (see
/// `AppSettingsState.hasDismissedWidgetPromo`). Renders nothing otherwise,
/// so it never disturbs unsupported platforms or widget tests without a
/// native host.
class WidgetPromoCard extends StatefulWidget {
  const WidgetPromoCard({super.key});

  @override
  State<WidgetPromoCard> createState() => _WidgetPromoCardState();
}

class _WidgetPromoCardState extends State<WidgetPromoCard> {
  /// Whether the card passed the async eligibility checks.
  bool _eligible = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  /// Verifies pin support and the absence of pinned instances.
  ///
  /// Stays hidden on any error (e.g. no native host in tests), so the card
  /// can only appear where the pin action is actionable.
  Future<void> _checkEligibility() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (supported != true) return;
      final installed = await HomeWidget.getInstalledWidgets();
      if (!mounted || installed.isNotEmpty) return;
      AppAnalytics.logWidgetPromoShown();
      setState(() => _eligible = true);
    } catch (_) {
      // Native widget integration unavailable: stay hidden.
    }
  }

  /// Asks the launcher to pin the compact weight widget.
  Future<void> _handlePin() async {
    AppAnalytics.logWidgetPromoPinClicked();
    try {
      await HomeWidget.requestPinWidget(
        name: WidgetSyncService.androidWidgetName,
        androidName: WidgetSyncService.androidWidgetName,
        qualifiedAndroidName:
            'com.ekerstudio.balance.${WidgetSyncService.androidWidgetName}',
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to request widget pin',
        fatal: false,
      );
    }
  }

  /// Dismisses the card permanently.
  void _handleDismiss() {
    AppAnalytics.logWidgetPromoDismissed();
    setState(() => _eligible = false);
    context.read<AppSettingsBloc>().add(const DismissWidgetPromo());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      buildWhen: (previous, current) =>
          previous.hasDismissedWidgetPromo != current.hasDismissedWidgetPromo,
      builder: (context, state) {
        if (state.hasDismissedWidgetPromo || !_eligible) {
          return const SizedBox.shrink();
        }

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final l10n = AppLocalizations.of(context);

        return Semantics(
          container: true,
          label: '${l10n.widgetPromoTitle}: ${l10n.widgetPromoBody}',
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.surfaceContainerHigh),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.widgets_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.widgetPromoTitle,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.widgetPromoBody,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: _handlePin,
                          child: Text(l10n.widgetPromoAdd),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.widgetPromoDismiss,
                    onPressed: _handleDismiss,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
