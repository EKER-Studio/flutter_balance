import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/widgets/state_message_card.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/today_content_section.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/today_shimmer_skeleton.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// The responsive view body for the Today screen resolving shimmer loading, error message cards, welcome states, and content section.
class TodayViewBody extends StatelessWidget {
  /// The active weight state.
  final WeightState state;

  /// Callback when user taps to add first weight measurement.
  final VoidCallback onAddFirstMeasurement;

  /// Creates a [TodayViewBody] widget.
  const TodayViewBody({
    super.key,
    required this.state,
    required this.onAddFirstMeasurement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentState = state;

    if (currentState is WeightInitial || currentState is WeightLoading) {
      return const TodayShimmerSkeleton();
    }

    final entries = _entriesFromState(currentState);
    if (currentState is WeightError && entries.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return StateMessageCard(
        icon: Icons.error_outline,
        iconColor: colorScheme.error,
        iconContainerColor: colorScheme.errorContainer,
        title: l10n.errorReadFailed,
        subtitle: currentState.errorType.localizedMessage(l10n),
        buttonLabel: l10n.retry,
        buttonIcon: Icons.refresh,
        onButtonPressed: () {
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        },
      );
    }

    if (entries.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return StateMessageCard(
        icon: Icons.monitor_weight_outlined,
        iconColor: colorScheme.primary,
        iconContainerColor: colorScheme.surfaceContainerHigh,
        title: l10n.welcomeTitle,
        subtitle: l10n.welcomeSubtitle,
        buttonLabel: l10n.addFirstMeasurement,
        buttonIcon: Icons.add,
        onButtonPressed: onAddFirstMeasurement,
      );
    }

    final filteredEntries = _filteredEntriesFromState(currentState);
    final errorType = currentState is WeightError
        ? currentState.errorType
        : null;

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settings) {
        return TodayContentSection(
          latestEntry: entries.first,
          filteredEntries: filteredEntries,
          timePeriod: currentState.timePeriod,
          errorType: errorType,
          measurementUnit: settings.measurementUnit,
          onPeriodChanged: (period) {
            AppAnalytics.logTodayDeltaPeriodSelected(period.name);
            context.read<WeightBloc>().add(ChangeChartFilter(period));
          },
          onRetry: () {
            context.read<WeightBloc>().add(const SubscribeToWeightChanges());
          },
        );
      },
    );
  }

  static List<WeightEntry> _entriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
  }

  static List<WeightEntry> _filteredEntriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final filteredEntries) => filteredEntries,
      WeightError(:final filteredEntries) => filteredEntries,
      _ => <WeightEntry>[],
    };
  }
}
