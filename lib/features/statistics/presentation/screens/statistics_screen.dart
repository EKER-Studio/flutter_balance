/// The Statistics tab: composite health metric cards and the BMI history chart.


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/features/statistics/presentation/widgets/bmi_chart_card.dart';
import 'package:balance/features/statistics/presentation/widgets/statistics_shimmer_skeleton.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/presentation/widgets/state_message_card.dart';

//// A consolidated statistics screen combining all health metrics into data-dense composite cards.
class StatisticsScreen extends StatelessWidget {
  /// Creates a [StatisticsScreen].
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppTopBar(title: l10n.tabStats),
            SliverSafeArea(
              top: false,
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<WeightBloc, WeightState>(
                  builder: (context, weightState) {
                    if (weightState is WeightInitial ||
                        weightState is WeightLoading) {
                      return const ClampedLayout(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: StatisticsShimmerSkeleton(),
                      );
                    }

                    final entries = switch (weightState) {
                      WeightLoaded(:final entries) => entries,
                      WeightError(:final entries) => entries,
                      _ => <WeightEntry>[],
                    };

                    if (entries.isEmpty) {
                      return ClampedLayout(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 32,
                        ),
                        child: StateMessageCard(
                          icon: Icons.bar_chart,
                          iconColor: Theme.of(context).colorScheme.primary,
                          iconContainerColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          title: l10n.noDataToAnalyze,
                          subtitle: l10n.noDataToAnalyzeSubtitle,
                          buttonLabel: l10n.addFirstMeasurement,
                          buttonIcon: Icons.add,
                          onButtonPressed: () => _showAddWeightSheet(context),
                        ),
                      );
                    }

                    final now = DateTime.now();
                    final streak = _calculateStreak(entries, now);
                    final compliancePct = _calculateTotalCompliance(
                      entries,
                      now,
                    );
                    final weeklyPace = _calculateWeeklyPace(entries);

                    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
                      builder: (context, settingsState) {
                        final unit = settingsState.measurementUnit;
                        final heightCm = settingsState.height;
                        final targetWeight = settingsState.targetWeight;

                        return ClampedLayout(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeroProgressAndGoalCard(
                                context,
                                entries: entries,
                                targetWeight: targetWeight,
                                weeklyPace: weeklyPace,
                                unit: unit,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              _buildHabitsAndActivityCard(
                                context,
                                streak: streak,
                                compliancePct: compliancePct,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              _buildCombinedWeightRangeCard(
                                context,
                                entries: entries,
                                unit: unit,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              BmiChartCard(
                                entries: entries,
                                heightCm: heightCm,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the hero progress and goal composite card.
  ///
  /// Shows the total change, weekly pace, and goal progress.
  Widget _buildHeroProgressAndGoalCard(
    BuildContext context, {
    required List<WeightEntry> entries,
    required double? targetWeight,
    required double? weeklyPace,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final sortedByDate = entries.reversed.toList(); // Ascending date
    final firstEntry = sortedByDate.first;
    final latestEntry = sortedByDate.last;

    final totalChangeKg = latestEntry.weightKg - firstEntry.weightKg;
    final totalChangeDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(totalChangeKg)
        : totalChangeKg;
    final unitLabel = unitLabelFor(unit);

    final sign = totalChangeDisplay > 0 ? '+' : '';
    final formattedValue =
        '$sign${totalChangeDisplay.toStringAsFixed(1)} $unitLabel';

    // Weekly pace text
    final paceDisplay = weeklyPace != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(weeklyPace) : weeklyPace)
        : null;
    final paceSign = (paceDisplay != null && paceDisplay > 0) ? '+' : '';
    final paceBadgeText = paceDisplay != null
        ? l10n.weeklyPaceBadge(
            '$paceSign${paceDisplay.toStringAsFixed(1)} $unitLabel',
          )
        : null;

    double? goalProgressPct;
    String? statusBadge;
    bool isSuccessBadge = true;

    if (targetWeight != null) {
      if (latestEntry.weightKg <= targetWeight) {
        statusBadge = '🏆 ${l10n.goalAchieved}';
        goalProgressPct = 100.0;
      } else {
        final distKg = latestEntry.weightKg - targetWeight;
        final distDisplay = unit == MeasurementUnit.imperial
            ? kgToLbs(distKg)
            : distKg;
        statusBadge =
            '${distDisplay.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
        isSuccessBadge = false;
        goalProgressPct = _calculateGoalProgressPct(
          startKg: firstEntry.weightKg,
          currentKg: latestEntry.weightKg,
          targetKg: targetWeight,
        );
      }
    } else if (totalChangeKg < 0) {
      statusBadge = '🎉 ${l10n.greatJob}';
    }

    final semanticLabel =
        '${l10n.totalProgress}: $formattedValue${statusBadge != null ? ", $statusBadge" : ""}';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.stars_outlined, size: 24, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.totalProgress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (statusBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isSuccessBadge ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusBadge,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? (isSuccessBadge
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800)
                                  : (isSuccessBadge
                                        ? Colors.green.shade300
                                        : Colors.orange.shade300),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formattedValue,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.sinceEntryDate(
                        _formatEntryDate(context, firstEntry.dateTime, l10n),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (paceBadgeText != null) ...[
                const SizedBox(height: 8),
                Text(
                  paceBadgeText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (goalProgressPct != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.goalProgress,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${goalProgressPct.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goalProgressPct / 100.0,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHigh,
                    color: cs.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the habits and activity composite card.
  ///
  /// Shows the logging streak and compliance.
  Widget _buildHabitsAndActivityCard(
    BuildContext context, {
    required int streak,
    required int compliancePct,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          '${l10n.loggingStreak}: ${l10n.streakDays(streak)}, ${l10n.monthlyCompliance}: $compliancePct%',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: _buildHabitMetricItem(
                  context,
                  icon: Icons.local_fire_department,
                  iconColor: cs.primary,
                  label: l10n.loggingStreak,
                  value: l10n.streakDays(streak),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 36,
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildHabitMetricItem(
                  context,
                  icon: Icons.insights,
                  iconColor: cs.primary,
                  label: l10n.monthlyCompliance,
                  value: '$compliancePct%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single metric column inside the habits and activity card.
  ///
  /// The column contains an icon, label, and value.
  Widget _buildHabitMetricItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Builds the combined weight range composite card.
  ///
  /// Shows the highest, lowest, and average weights.
  Widget _buildCombinedWeightRangeCard(
    BuildContext context, {
    required List<WeightEntry> entries,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final unitLabel = unitLabelFor(unit);

    final maxEntry = entries.reduce((a, b) => a.weightKg > b.weightKg ? a : b);
    final maxDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(maxEntry.weightKg)
        : maxEntry.weightKg;
    final maxDateText = _formatEntryDate(context, maxEntry.dateTime, l10n);

    final minEntry = entries.reduce((a, b) => a.weightKg < b.weightKg ? a : b);
    final minDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(minEntry.weightKg)
        : minEntry.weightKg;
    final minDateText = _formatEntryDate(context, minEntry.dateTime, l10n);

    final weights = entries.map((e) => e.weightKg).toList();
    final avgWeightKg = weights.reduce((a, b) => a + b) / weights.length;
    final avgDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(avgWeightKg)
        : avgWeightKg;

    return Semantics(
      container: true,
      label:
          '${l10n.weightRangeSemanticsPrefix}${l10n.highest} ${maxDisplay.toStringAsFixed(1)} $unitLabel, ${l10n.lowest} ${minDisplay.toStringAsFixed(1)} $unitLabel, ${l10n.averageWeight} ${avgDisplay.toStringAsFixed(1)} $unitLabel',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 24, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.weightRangeCardTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeightDetailRow(
                context,
                icon: Icons.north_east,
                iconColor: cs.error,
                label: l10n.highest,
                value: '${maxDisplay.toStringAsFixed(1)} $unitLabel',
                date: maxDateText,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, thickness: 0.5),
              ),
              _buildWeightDetailRow(
                context,
                icon: Icons.south_east,
                iconColor: cs.primary,
                label: l10n.lowest,
                value: '${minDisplay.toStringAsFixed(1)} $unitLabel',
                date: minDateText,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, thickness: 0.5),
              ),
              _buildWeightDetailRow(
                context,
                icon: Icons.bar_chart,
                iconColor: cs.secondary,
                label: l10n.averageWeight,
                value: '${avgDisplay.toStringAsFixed(1)} $unitLabel',
                date: l10n.allEntriesLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds one detail row inside the combined weight range card.
  ///
  /// The row contains an icon, label, date, and formatted value.
  Widget _buildWeightDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String date,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                date,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Calculates the weekly weight change pace over the last 30 days.
  double? _calculateWeeklyPace(List<WeightEntry> entries) {
    if (entries.length < 2) return null;

    final sorted = entries.reversed.toList(); // Ascending date
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final recentEntries = sorted
        .where((e) => e.dateTime.isAfter(monthAgo))
        .toList();
    if (recentEntries.length < 2) return null;

    final first = recentEntries.first;
    final last = recentEntries.last;

    final days = last.dateTime.difference(first.dateTime).inDays;
    if (days < 1) return 0.0;

    final weeks = days / 7.0;
    final diffKg = last.weightKg - first.weightKg;

    return diffKg / weeks;
  }

  /// Calculates the percentage progress toward the goal.
  double _calculateGoalProgressPct({
    required double startKg,
    required double currentKg,
    required double targetKg,
  }) {
    if (startKg == targetKg) return 100.0;

    final totalNeeded = (startKg - targetKg).abs();
    final isLosing = startKg > targetKg;
    final achieved = isLosing ? (startKg - currentKg) : (currentKg - startKg);

    if (achieved <= 0) return 0.0;

    final pct = (achieved / totalNeeded) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  /// Calculates the current daily streak.
  int _calculateStreak(List<WeightEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;

    final dates =
        entries
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final todayDate = DateTime(now.year, now.month, now.day);
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

  /// Calculates the all-time compliance percentage.
  ///
  /// Evaluates unique logged days over the total days since the first entry.
  int _calculateTotalCompliance(List<WeightEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;

    final firstDate = entries
        .map((e) => e.dateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);

    int totalDays = today.difference(start).inDays + 1;
    if (totalDays <= 0) totalDays = 1;

    final loggedDays = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;
    return ((loggedDays / totalDays) * 100).round().clamp(0, 100);
  }

  /// Formats a measurement entry [date].
  ///
  /// Returns strings like "15 Sty 2023" or "Dzisiaj".
  String _formatEntryDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return l10n.today;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Shows the [AddWeightSheet] dialog.
  void _showAddWeightSheet(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<WeightBloc>(),
        child: const AddWeightSheet(),
      ),
    );
  }
}
