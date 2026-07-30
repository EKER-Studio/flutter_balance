import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/latest_measurement_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/state_message_card.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';

/// Tab 1: Today Screen displaying daily summary, BMI & goal card, weight trend chart, and latest measurement tile.
class TodayScreen extends StatelessWidget {
  /// Optional callback to navigate to the Statistics tab when the latest measurement card is tapped.
  final VoidCallback? onNavigateToStats;

  /// Optional callback to navigate to Settings when profile icon is pressed.
  final VoidCallback? onNavigateToSettings;

  /// Creates a [TodayScreen] with optional navigation callbacks.
  const TodayScreen({
    super.key,
    this.onNavigateToStats,
    this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.todayTabTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () {
              if (onNavigateToSettings != null) {
                onNavigateToSettings!();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<WeightBloc, WeightState>(
          listenWhen: (previous, current) => current is WeightError,
          listener: (context, state) {
            if (state is WeightError) {
              final message =
                  state.message ?? state.errorType.localizedMessage(l10n);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  action: SnackBarAction(
                    label: l10n.retry,
                    onPressed: () {
                      context.read<WeightBloc>().add(
                        const SubscribeToWeightChanges(),
                      );
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is WeightInitial || state is WeightLoading) {
              return const ClampedLayout(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TodayShimmerSkeleton(),
              );
            }

            final entries = switch (state) {
              WeightLoaded(:final entries) => entries,
              WeightError(:final entries) => entries,
              _ => <WeightEntry>[],
            };

            if (state is WeightError && entries.isEmpty) {
              final errorText =
                  state.message ?? state.errorType.localizedMessage(l10n);
              return ClampedLayout(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: StateMessageCard(
                  icon: Icons.error_outline,
                  iconColor: Theme.of(context).colorScheme.error,
                  iconContainerColor: Theme.of(
                    context,
                  ).colorScheme.errorContainer,
                  title: l10n.errorReadFailed,
                  subtitle: errorText,
                  buttonLabel: l10n.retry,
                  buttonIcon: Icons.refresh,
                  onButtonPressed: () {
                    context.read<WeightBloc>().add(
                      const SubscribeToWeightChanges(),
                    );
                  },
                ),
              );
            }

            if (entries.isEmpty) {
              return StateMessageCard(
                icon: Icons.monitor_weight_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                iconContainerColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHigh,
                title: l10n.welcomeTitle,
                subtitle: l10n.welcomeSubtitle,
                buttonLabel: l10n.addFirstMeasurement,
                buttonIcon: Icons.add,
                onButtonPressed: () => _showAddWeightSheet(context),
              );
            }

            final filteredEntries = switch (state) {
              WeightLoaded(:final filteredEntries) => filteredEntries,
              WeightError(:final filteredEntries) => filteredEntries,
              _ => <WeightEntry>[],
            };

            final sortedEntries = entries.toList();

            final latestEntry = sortedEntries.first;
            final latestWeight = latestEntry.weightKg;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<WeightBloc>().add(
                  const SubscribeToWeightChanges(),
                );
              },
              child: ClampedLayout(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state is WeightError) ...[
                        _buildInlineErrorBanner(
                          context,
                          state.errorType,
                          state.message,
                          l10n,
                        ),
                        const SizedBox(height: 16),
                      ],
                      HealthSummaryCard(
                        latestWeightKg: latestWeight,
                        lastUpdated: latestEntry.dateTime,
                      ),
                      const SizedBox(height: 16),
                      _buildWeightTrendCard(
                        context,
                        filteredEntries,
                        state.timePeriod,
                      ),
                      const SizedBox(height: 16),
                      LatestMeasurementCard(
                        latestEntry: latestEntry,
                        onTap: () {
                          if (onNavigateToStats != null) {
                            onNavigateToStats!();
                          }
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<WeightBloc, WeightState>(
        builder: (context, state) {
          final entries = switch (state) {
            WeightLoaded(:final entries) => entries,
            WeightError(:final entries) => entries,
            _ => <WeightEntry>[],
          };
          if (entries.isEmpty ||
              state is WeightInitial ||
              state is WeightLoading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _showAddWeightSheet(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildInlineErrorBanner(
    BuildContext context,
    WeightErrorType errorType,
    String? message,
    AppLocalizations l10n,
  ) {
    final l10n = AppLocalizations.of(context);
    final errorText = message ?? errorType.localizedMessage(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<WeightBloc>().add(const SubscribeToWeightChanges());
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrendCard(
    BuildContext context,
    List<WeightEntry> filteredEntries,
    TimePeriod period,
  ) {
    final l10n = AppLocalizations.of(context);

    return BlocSelector<AppSettingsBloc, AppSettingsState, double?>(
      selector: (s) => s.targetWeight,
      builder: (context, targetWeight) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 4,
                    bottom: 8,
                  ),
                  child: Text(
                    l10n.weightTrend,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                WeightChart(
                  entries: filteredEntries,
                  period: period,
                  chartHeight: 200,
                  onPeriodChanged: (p) =>
                      context.read<WeightBloc>().add(ChangeChartFilter(p)),
                  targetWeight: targetWeight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddWeightSheet());
  }
}
