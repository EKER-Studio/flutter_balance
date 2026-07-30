import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';

/// Tab 3: Statistics Screen providing habit-tracker analytics, streaks, and trends.
class StatisticsScreen extends StatelessWidget {
  /// Creates [StatisticsScreen].
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabStats),
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
            final period = state.timePeriod;

            final streak = _calculateStreak(entries);
            final compliancePct = _calculateMonthlyCompliance(entries);

            return ClampedLayout(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHabitSummaryCards(context, streak, compliancePct, l10n),
                    const SizedBox(height: 16),
                    _buildMetricsSection(context, entries, l10n),
                    const SizedBox(height: 16),
                    BlocSelector<AppSettingsBloc, AppSettingsState, double?>(
                      selector: (s) => s.targetWeight,
                      builder: (context, targetWeight) {
                        return WeightChart(
                          entries: filteredEntries,
                          period: period,
                          onPeriodChanged: (p) => context
                              .read<WeightBloc>()
                              .add(ChangeChartFilter(p)),
                          targetWeight: targetWeight,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHabitSummaryCards(
    BuildContext context,
    int streak,
    int compliancePct,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: cs.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.loggingStreak,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.streakDays(streak),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights, color: cs.onSecondaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.monthlyCompliance,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$compliancePct%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    List<WeightEntry> entries,
    AppLocalizations l10n,
  ) {
    final weights = entries.map((e) => e.weightKg).toList();
    final minWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a > b ? a : b);
    final avgWeight = weights.isEmpty
        ? null
        : weights.reduce((a, b) => a + b) / weights.length;

    final netChange = (entries.length >= 2)
        ? (entries.first.weightKg - entries.last.weightKg)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.stats,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: l10n.lowest,
                    value: minWeight != null ? '${minWeight.toStringAsFixed(1)} kg' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: l10n.highest,
                    value: maxWeight != null ? '${maxWeight.toStringAsFixed(1)} kg' : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: l10n.averageWeight,
                    value: avgWeight != null ? '${avgWeight.toStringAsFixed(1)} kg' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: l10n.totalProgress,
                    value: netChange != null
                        ? '${netChange > 0 ? '+' : ''}${netChange.toStringAsFixed(1)} kg'
                        : '—',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  int _calculateStreak(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayDate) ? todayDate : yesterdayDate;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateMonthlyCompliance(List<WeightEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthAgo = today.subtract(const Duration(days: 30));

    final loggedDays = entries
        .where((e) => e.dateTime.isAfter(monthAgo))
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;

    return ((loggedDays / 30) * 100).round();
  }
}
