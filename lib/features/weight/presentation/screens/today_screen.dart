import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
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
              l10n.appTitle == 'PureWeight' ? 'Waga i BMI' : l10n.appTitle,
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
        child: BlocBuilder<WeightBloc, WeightState>(
          builder: (context, state) {
            final entries = switch (state) {
              WeightLoaded(:final entries) => entries,
              WeightError(:final entries) => entries,
              _ => <WeightEntry>[],
            };

            final filteredEntries = switch (state) {
              WeightLoaded(:final filteredEntries) => filteredEntries,
              WeightError(:final filteredEntries) => filteredEntries,
              _ => <WeightEntry>[],
            };

            final sortedEntries = List<WeightEntry>.from(entries)
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            final latestEntry = sortedEntries.isNotEmpty ? sortedEntries.first : null;
            final latestWeight = latestEntry?.weightKg ?? 0.0;

            return ClampedLayout(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HealthSummaryCard(
                      latestWeightKg: latestWeight,
                      lastUpdated: latestEntry?.dateTime,
                    ),
                    const SizedBox(height: 16),
                    _buildWeightTrendCard(
                      context,
                      filteredEntries,
                      state.timePeriod,
                    ),
                    const SizedBox(height: 16),
                    _buildLatestMeasurementCard(context, latestEntry, l10n),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeightSheet(context),
        child: const Icon(Icons.add),
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
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 8),
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

  Widget _buildLatestMeasurementCard(
    BuildContext context,
    WeightEntry? latestEntry,
    AppLocalizations l10n,
  ) {
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;

    if (latestEntry == null) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.scale,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.emptyState,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayWeight = unit == MeasurementUnit.imperial
        ? kgToLbs(latestEntry.weightKg)
        : latestEntry.weightKg;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lb' : 'kg';
    final timestampText = _formatTimestamp(context, latestEntry.dateTime, l10n);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          if (onNavigateToStats != null) {
            onNavigateToStats!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.scale,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.latestMeasurement,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timestampText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    displayWeight.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unitLabel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(
    BuildContext context,
    DateTime dateTime,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final timeStr = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(dateTime);

    if (isToday) {
      return 'Dzisiaj, $timeStr';
    }
    final dateStr = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(dateTime);
    return '$dateStr, $timeStr';
  }

  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddWeightSheet(),
    );
  }
}
