import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

/// Tab 1: Today Screen displaying daily summary, today's recorded entries, and quick actions.
class TodayScreen extends StatelessWidget {
  /// Creates [TodayScreen].
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final dateHeaderStr = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(now);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.tabToday),
            Text(
              dateHeaderStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<WeightBloc, WeightState>(
          builder: (context, state) {
            final entries = switch (state) {
              WeightLoaded(:final entries) => entries,
              WeightError(:final entries) => entries,
              _ => <WeightEntry>[],
            };

            final todayEntries = entries.where((e) {
              return e.dateTime.year == now.year &&
                  e.dateTime.month == now.month &&
                  e.dateTime.day == now.day;
            }).toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            final latestWeight = entries.isNotEmpty ? entries.first.weightKg : 0.0;

            return ClampedLayout(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (latestWeight > 0)
                      HealthSummaryCard(latestWeightKg: latestWeight),
                    const SizedBox(height: 16),
                    _buildTodayCard(context, todayEntries, l10n),
                    const SizedBox(height: 16),
                    _buildRecentChartCard(context, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addWeight),
      ),
    );
  }

  Widget _buildTodayCard(
    BuildContext context,
    List<WeightEntry> todayEntries,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.todaySummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: todayEntries.isNotEmpty
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    todayEntries.isNotEmpty
                        ? l10n.multipleEntries(todayEntries.length)
                        : l10n.missingData,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: todayEntries.isNotEmpty
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todayEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noEntriesToday,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: todayEntries.map((e) {
                  final timeStr = DateFormat.jm(
                    Localizations.localeOf(context).toString(),
                  ).format(e.dateTime);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.monitor_weight_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      '${e.weightKg.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      e.note != null && e.note!.isNotEmpty
                          ? '$timeStr • ${e.note}'
                          : timeStr,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        context.read<WeightBloc>().add(DeleteWeight(e.id));
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChartCard(BuildContext context, WeightState state) {
    final filtered = switch (state) {
      WeightLoaded(:final filteredEntries) => filteredEntries,
      WeightError(:final filteredEntries) => filteredEntries,
      _ => <WeightEntry>[],
    };
    final period = state.timePeriod;

    return BlocSelector<AppSettingsBloc, AppSettingsState, double?>(
      selector: (s) => s.targetWeight,
      builder: (context, targetWeight) {
        return WeightChart(
          entries: filtered,
          period: period,
          onPeriodChanged: (p) =>
              context.read<WeightBloc>().add(ChangeChartFilter(p)),
          targetWeight: targetWeight,
        );
      },
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddWeightSheet(),
    );
  }
}
