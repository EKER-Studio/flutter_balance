import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/statistics_shimmer_skeleton.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/app_top_bar.dart';
import 'package:pure_weight/presentation/widgets/state_message_card.dart';
import 'package:pure_weight/presentation/widgets/weight_chart.dart';

/// Tab 3: Statistics Screen providing Garmin-inspired health analytics, streaks, trends, and detailed key metrics.
class StatisticsScreen extends StatelessWidget {
  /// Creates [StatisticsScreen].
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
                          iconContainerColor:
                              Theme.of(context).colorScheme.surfaceContainerHigh,
                          title: l10n.noDataToAnalyze,
                          subtitle: l10n.noDataToAnalyzeSubtitle,
                          buttonLabel: l10n.addFirstMeasurement,
                          buttonIcon: Icons.add,
                          onButtonPressed: () => _showAddWeightSheet(context),
                        ),
                      );
                    }

                    final filteredEntries = switch (weightState) {
                      WeightLoaded(:final filteredEntries) => filteredEntries,
                      WeightError(:final filteredEntries) => filteredEntries,
                      _ => <WeightEntry>[],
                    };
                    final period = weightState.timePeriod;
                    final now = DateTime.now();
                    final streak = _calculateStreak(entries, now);
                    final compliancePct = _calculateMonthlyCompliance(
                      entries,
                      now,
                    );

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
                              _buildHeroProgressBanner(
                                context,
                                entries: entries,
                                targetWeight: targetWeight,
                                unit: unit,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              _buildHabitSummaryCards(
                                context,
                                streak: streak,
                                compliancePct: compliancePct,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              _buildHeroTrendCard(
                                context,
                                filteredEntries: filteredEntries,
                                period: period,
                                targetWeight: targetWeight,
                                unit: unit,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 16),
                              _buildKeyMetricsGrid(
                                context,
                                allEntries: entries,
                                filteredEntries: filteredEntries.isNotEmpty
                                    ? filteredEntries
                                    : entries,
                                unit: unit,
                                heightCm: heightCm,
                                l10n: l10n,
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

  /// Builds the top hero progress banner displaying total net weight change and motivational status.
  Widget _buildHeroProgressBanner(
    BuildContext context, {
    required List<WeightEntry> entries,
    required double? targetWeight,
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
    final formattedValue = '$sign${totalChangeDisplay.toStringAsFixed(1)} $unitLabel';

    String? statusBadge;
    if (targetWeight != null) {
      if (latestEntry.weightKg <= targetWeight) {
        statusBadge = '🏆 ${l10n.goalAchieved}';
      } else {
        final distKg = latestEntry.weightKg - targetWeight;
        final distDisplay = unit == MeasurementUnit.imperial
            ? kgToLbs(distKg)
            : distKg;
        statusBadge = '${distDisplay.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
      }
    } else if (totalChangeKg < 0) {
      statusBadge = '🎉 ${l10n.greatJob}';
    }

    final semanticLabel = '${l10n.totalProgress}: $formattedValue${statusBadge != null ? ", $statusBadge" : ""}';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Card(
        elevation: 0,
        color: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.totalLostHeader,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedValue,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (statusBadge != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusBadge,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds habit summary cards for logging streak and monthly compliance.
  Widget _buildHabitSummaryCards(
    BuildContext context, {
    required int streak,
    required int compliancePct,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            label: '${l10n.loggingStreak}: ${l10n.streakDays(streak)}',
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.loggingStreak,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.streakDays(streak),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            container: true,
            label: '${l10n.monthlyCompliance}: $compliancePct%',
            child: Card(
              elevation: 0,
              color: cs.secondaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
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
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        ),
      ],
    );
  }

  /// Builds the Hero Weight Trend card containing title, current value, trend badge, and line chart.
  Widget _buildHeroTrendCard(
    BuildContext context, {
    required List<WeightEntry> filteredEntries,
    required TimePeriod period,
    required double? targetWeight,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final latestKg = filteredEntries.isNotEmpty ? filteredEntries.first.weightKg : null;
    final formattedLatest = latestKg != null ? formatWeight(latestKg, unit) : '—';
    final unitLabel = unitLabelFor(unit);

    final percentChange = _calculatePercentChange(filteredEntries);

    return Semantics(
      container: true,
      label: '${l10n.weightTrend}: $formattedLatest',
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weightTrend,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedLatest,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (latestKg != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              unitLabel,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (percentChange != null)
                    _buildTrendBadge(context, percentChange: percentChange),
                ],
              ),
              const SizedBox(height: 16),
              WeightChart(
                entries: filteredEntries,
                period: period,
                onPeriodChanged: (p) =>
                    context.read<WeightBloc>().add(ChangeChartFilter(p)),
                targetWeight: targetWeight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a pill-shaped trend badge showing percentage change.
  Widget _buildTrendBadge(
    BuildContext context, {
    required double percentChange,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDown = percentChange < 0;
    final isUp = percentChange > 0;

    final badgeColor = isDown
        ? cs.secondaryContainer
        : (isUp ? cs.errorContainer : cs.surfaceContainerHigh);
    final contentColor = isDown
        ? cs.onSecondaryContainer
        : (isUp ? cs.onErrorContainer : cs.onSurfaceVariant);
    final icon = isDown
        ? Icons.trending_down
        : (isUp ? Icons.trending_up : Icons.trending_flat);

    final sign = percentChange > 0 ? '+' : '';
    final formattedValue = '$sign${percentChange.toStringAsFixed(1)}%';
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.trendPercentChange(formattedValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: contentColor),
            const SizedBox(width: 4),
            Text(
              formattedValue,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a 2x2 Bento Grid section for key metrics including exact dates and period change.
  Widget _buildKeyMetricsGrid(
    BuildContext context, {
    required List<WeightEntry> allEntries,
    required List<WeightEntry> filteredEntries,
    required MeasurementUnit unit,
    required double? heightCm,
    required AppLocalizations l10n,
  }) {
    final unitLabel = unitLabelFor(unit);

    // Highest Weight calculation
    final maxEntry = allEntries.reduce(
      (a, b) => a.weightKg > b.weightKg ? a : b,
    );
    final maxDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(maxEntry.weightKg)
        : maxEntry.weightKg;
    final maxDateText = _formatEntryDate(context, maxEntry.dateTime, l10n);

    // Lowest Weight calculation
    final minEntry = allEntries.reduce(
      (a, b) => a.weightKg < b.weightKg ? a : b,
    );
    final minDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(minEntry.weightKg)
        : minEntry.weightKg;
    final minDateText = _formatEntryDate(context, minEntry.dateTime, l10n);

    // Average Weight in selected period calculation
    final periodWeights = filteredEntries.map((e) => e.weightKg).toList();
    final avgWeightKg = periodWeights.isEmpty
        ? null
        : periodWeights.reduce((a, b) => a + b) / periodWeights.length;
    final avgDisplay = avgWeightKg != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(avgWeightKg) : avgWeightKg)
        : null;

    final sortedFiltered = filteredEntries.reversed.toList(); // Ascending date
    final periodChangeKg = (sortedFiltered.length >= 2)
        ? (sortedFiltered.last.weightKg - sortedFiltered.first.weightKg)
        : null;
    final periodChangeDisplay = periodChangeKg != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(periodChangeKg) : periodChangeKg)
        : null;

    final periodSubText = periodChangeDisplay != null
        ? '${periodChangeDisplay > 0 ? '+' : ''}${periodChangeDisplay.toStringAsFixed(1)} $unitLabel w okresie'
        : unitLabel;

    // Average BMI in selected period
    final bmi = (avgWeightKg != null && heightCm != null && heightCm > 0)
        ? avgWeightKg / ((heightCm / 100) * (heightCm / 100))
        : null;
    final bmiCategory = bmi != null && bmi.isFinite
        ? BmiCategory.fromBmi(bmi)
        : null;
    final bmiCategoryText = bmiCategory != null
        ? bmiCategory.localizedName(l10n)
        : '—';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                context,
                title: l10n.highest,
                value: maxDisplay.toStringAsFixed(1),
                subtitle: maxDateText,
                icon: Icons.north_east,
                iconColor: Theme.of(context).colorScheme.error,
                semanticLabel: '${l10n.highest}: ${maxDisplay.toStringAsFixed(1)} $unitLabel, $maxDateText',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                context,
                title: l10n.lowest,
                value: minDisplay.toStringAsFixed(1),
                subtitle: minDateText,
                icon: Icons.south_east,
                iconColor: Theme.of(context).colorScheme.primary,
                semanticLabel: '${l10n.lowest}: ${minDisplay.toStringAsFixed(1)} $unitLabel, $minDateText',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                context,
                title: l10n.averageWeight,
                value: avgDisplay != null ? avgDisplay.toStringAsFixed(1) : '—',
                subtitle: periodSubText,
                icon: Icons.analytics_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                semanticLabel: '${l10n.averageWeight}: ${avgDisplay != null ? "${avgDisplay.toStringAsFixed(1)} $unitLabel" : l10n.missingData}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                context,
                title: l10n.bmi,
                value: bmi != null ? bmi.toStringAsFixed(1) : '—',
                subtitle: bmiCategoryText,
                icon: Icons.monitor_heart_outlined,
                iconColor: Theme.of(context).colorScheme.secondary,
                semanticLabel: '${l10n.bmi}: ${bmi != null ? "${bmi.toStringAsFixed(1)}, $bmiCategoryText" : l10n.missingData}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an individual Bento Grid metric card with 28dp rounded corners.
  Widget _buildBentoCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
    required String semanticLabel,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: valueColor ?? cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculates percentage weight change between the first and last entry of [entries].
  double? _calculatePercentChange(List<WeightEntry> entries) {
    if (entries.length < 2) return null;

    final sorted = entries.reversed.toList(); // Ascending date

    final first = sorted.first.weightKg;
    final last = sorted.last.weightKg;

    if (first == 0) return null;

    return ((last - first) / first) * 100;
  }

  /// Calculates current daily streak.
  int _calculateStreak(List<WeightEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;

    final dates = entries
        .map(
          (e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
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

  /// Calculates monthly compliance percentage (logged days in last 30 days).
  int _calculateMonthlyCompliance(List<WeightEntry> entries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monthAgo = today.subtract(Duration(days: monthlyComplianceDays));

    final loggedDays = entries
        .where((e) => e.dateTime.isAfter(monthAgo))
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;

    return ((loggedDays / monthlyComplianceDays) * 100).round();
  }

  /// Formats a measurement entry date (e.g. "15 Sty 2023" or "Dzisiaj").
  String _formatEntryDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return l10n.lastUpdatedToday.replaceFirst('Ostatnia aktualizacja: ', '');
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Shows the [AddWeightSheet] modal bottom sheet.
  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddWeightSheet(),
    );
  }
}
