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

/// Active layout variant for testing and comparing Statistics Screen designs.
enum StatsVariant { variantA, variantB }

/// Tab 3: Statistics Screen providing card-based health analytics with selectable Variant A & Variant B layouts.
class StatisticsScreen extends StatefulWidget {
  /// Creates [StatisticsScreen].
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsVariant _selectedVariant = StatsVariant.variantA;

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

                    final now = DateTime.now();
                    final streak = _calculateStreak(entries, now);
                    final compliancePct = _calculateMonthlyCompliance(
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
                              _buildVariantSelector(context),
                              const SizedBox(height: 16),
                              if (_selectedVariant == StatsVariant.variantA)
                                ..._buildVariantA(
                                  context,
                                  entries: entries,
                                  targetWeight: targetWeight,
                                  unit: unit,
                                  heightCm: heightCm,
                                  streak: streak,
                                  compliancePct: compliancePct,
                                  weeklyPace: weeklyPace,
                                  l10n: l10n,
                                )
                              else
                                ..._buildVariantB(
                                  context,
                                  entries: entries,
                                  targetWeight: targetWeight,
                                  unit: unit,
                                  heightCm: heightCm,
                                  streak: streak,
                                  compliancePct: compliancePct,
                                  weeklyPace: weeklyPace,
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

  /// Builds a segmented control button to switch between Variant A and Variant B live in app.
  Widget _buildVariantSelector(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SegmentedButton<StatsVariant>(
        segments: const [
          ButtonSegment(
            value: StatsVariant.variantA,
            label: Text('Wariant A (Karty + Cel)'),
            icon: Icon(Icons.style_outlined),
          ),
          ButtonSegment(
            value: StatsVariant.variantB,
            label: Text('Wariant B (Sekcja dolna)'),
            icon: Icon(Icons.grid_view_outlined),
          ),
        ],
        selected: {_selectedVariant},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedVariant = newSelection.first;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: cs.outlineVariant),
          ),
        ),
      ),
    );
  }

  /// Builds Variant A: Thematic Cards with Goal Progress Bar and Pace Row.
  List<Widget> _buildVariantA(
    BuildContext context, {
    required List<WeightEntry> entries,
    required double? targetWeight,
    required MeasurementUnit unit,
    required double? heightCm,
    required int streak,
    required int compliancePct,
    required double? weeklyPace,
    required AppLocalizations l10n,
  }) {
    return [
      _buildGoalProgressHeroCard(
        context,
        entries: entries,
        targetWeight: targetWeight,
        unit: unit,
        l10n: l10n,
      ),
      const SizedBox(height: 16),
      _buildHabitRowVariantA(
        context,
        streak: streak,
        compliancePct: compliancePct,
        weeklyPace: weeklyPace,
        unit: unit,
        l10n: l10n,
      ),
      const SizedBox(height: 16),
      _buildKeyMetricsGrid(
        context,
        entries: entries,
        unit: unit,
        heightCm: heightCm,
        l10n: l10n,
      ),
    ];
  }

  /// Builds Variant B: Classic Grid with Expanded Bottom Metrics Row.
  List<Widget> _buildVariantB(
    BuildContext context, {
    required List<WeightEntry> entries,
    required double? targetWeight,
    required MeasurementUnit unit,
    required double? heightCm,
    required int streak,
    required int compliancePct,
    required double? weeklyPace,
    required AppLocalizations l10n,
  }) {
    return [
      _buildHeroProgressCard(
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
      _buildKeyMetricsGrid(
        context,
        entries: entries,
        unit: unit,
        heightCm: heightCm,
        l10n: l10n,
      ),
      const SizedBox(height: 16),
      _buildBottomAnalyticsRow(
        context,
        totalEntries: entries.length,
        weeklyPace: weeklyPace,
        unit: unit,
        l10n: l10n,
      ),
    ];
  }

  /// Variant A: Goal Progress Hero Card featuring net progress, goal progress bar, and distance badge.
  Widget _buildGoalProgressHeroCard(
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

    double? goalProgressPct;
    String? statusBadge;

    if (targetWeight != null) {
      if (latestEntry.weightKg <= targetWeight) {
        statusBadge = '🏆 ${l10n.goalAchieved}';
        goalProgressPct = 100.0;
      } else {
        final distKg = latestEntry.weightKg - targetWeight;
        final distDisplay = unit == MeasurementUnit.imperial
            ? kgToLbs(distKg)
            : distKg;
        statusBadge = '${distDisplay.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
        goalProgressPct = _calculateGoalProgressPct(
          startKg: firstEntry.weightKg,
          currentKg: latestEntry.weightKg,
          targetKg: targetWeight,
        );
      }
    } else if (totalChangeKg < 0) {
      statusBadge = '🎉 ${l10n.greatJob}';
    }

    return Card(
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
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
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
                    'od ${_formatEntryDate(context, firstEntry.dateTime, l10n)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (goalProgressPct != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Postęp celu',
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
    );
  }

  /// Variant A: 3-column habit & pace summary cards.
  Widget _buildHabitRowVariantA(
    BuildContext context, {
    required int streak,
    required int compliancePct,
    required double? weeklyPace,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final unitLabel = unitLabelFor(unit);

    final paceDisplay = weeklyPace != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(weeklyPace) : weeklyPace)
        : null;
    final paceSign = (paceDisplay != null && paceDisplay > 0) ? '+' : '';
    final paceText = paceDisplay != null
        ? '$paceSign${paceDisplay.toStringAsFixed(1)} $unitLabel/tydz.'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _buildMiniHabitCard(
            context,
            icon: Icons.local_fire_department,
            iconColor: cs.primary,
            title: l10n.loggingStreak,
            value: l10n.streakDays(streak),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniHabitCard(
            context,
            icon: Icons.insights,
            iconColor: cs.secondary,
            title: 'Regularność',
            value: '$compliancePct%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniHabitCard(
            context,
            icon: Icons.speed,
            iconColor: cs.tertiary,
            title: 'Tempo',
            value: paceText,
          ),
        ),
      ],
    );
  }

  /// Helper for compact mini habit cards in Variant A.
  Widget _buildMiniHabitCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Variant B: Additional bottom analytics section card row (Weekly Pace + Total Entries Count).
  Widget _buildBottomAnalyticsRow(
    BuildContext context, {
    required int totalEntries,
    required double? weeklyPace,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final unitLabel = unitLabelFor(unit);

    final paceDisplay = weeklyPace != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(weeklyPace) : weeklyPace)
        : null;
    final paceSign = (paceDisplay != null && paceDisplay > 0) ? '+' : '';
    final paceText = paceDisplay != null
        ? '$paceSign${paceDisplay.toStringAsFixed(1)} $unitLabel/tydzień'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _buildBentoCard(
            context,
            title: 'Tygodniowe tempo',
            value: paceText,
            subtitle: 'Średnia z 30 dni',
            icon: Icons.speed,
            iconColor: cs.tertiary,
            semanticLabel: 'Tygodniowe tempo: $paceText',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBentoCard(
            context,
            title: 'Liczba pomiarów',
            value: '$totalEntries',
            subtitle: 'Wszystkie wpisy',
            icon: Icons.format_list_bulleted,
            iconColor: cs.primary,
            semanticLabel: 'Liczba pomiarów: $totalEntries',
          ),
        ),
      ],
    );
  }

  /// Standard Hero progress card used in Variant B.
  Widget _buildHeroProgressCard(
    BuildContext context, {
    required List<WeightEntry> entries,
    required double? targetWeight,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    final cs = Theme.of(context).colorScheme;
    final sortedByDate = entries.reversed.toList();
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
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stars_outlined,
                    size: 24,
                    color: cs.primary,
                  ),
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
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
                      'od ${_formatEntryDate(context, firstEntry.dateTime, l10n)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  /// Builds 2-column habit summary cards used in Variant B.
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
                          Icons.insights,
                          color: cs.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.monthlyCompliance,
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
                      '$compliancePct%',
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
      ],
    );
  }

  /// Builds a 2x2 Bento Grid section for key metrics with exact dates and BMI categories.
  Widget _buildKeyMetricsGrid(
    BuildContext context, {
    required List<WeightEntry> entries,
    required MeasurementUnit unit,
    required double? heightCm,
    required AppLocalizations l10n,
  }) {
    final unitLabel = unitLabelFor(unit);

    // Highest Weight calculation
    final maxEntry = entries.reduce(
      (a, b) => a.weightKg > b.weightKg ? a : b,
    );
    final maxDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(maxEntry.weightKg)
        : maxEntry.weightKg;
    final maxDateText = _formatEntryDate(context, maxEntry.dateTime, l10n);

    // Lowest Weight calculation
    final minEntry = entries.reduce(
      (a, b) => a.weightKg < b.weightKg ? a : b,
    );
    final minDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(minEntry.weightKg)
        : minEntry.weightKg;
    final minDateText = _formatEntryDate(context, minEntry.dateTime, l10n);

    // Average Weight calculation across all measurements
    final weights = entries.map((e) => e.weightKg).toList();
    final avgWeightKg = weights.reduce((a, b) => a + b) / weights.length;
    final avgDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(avgWeightKg)
        : avgWeightKg;

    // Average BMI calculation
    final bmi = (heightCm != null && heightCm > 0)
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
                value: avgDisplay.toStringAsFixed(1),
                subtitle: '$unitLabel (średnia)',
                icon: Icons.analytics_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                semanticLabel: '${l10n.averageWeight}: ${avgDisplay.toStringAsFixed(1)} $unitLabel',
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

  /// Builds an individual Bento Grid metric card with uniform 28dp rounded corners.
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

  /// Calculates weekly weight change pace over the last 30 days.
  double? _calculateWeeklyPace(List<WeightEntry> entries) {
    if (entries.length < 2) return null;

    final sorted = entries.reversed.toList(); // Ascending date
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final recentEntries = sorted.where((e) => e.dateTime.isAfter(monthAgo)).toList();
    if (recentEntries.length < 2) return null;

    final first = recentEntries.first;
    final last = recentEntries.last;

    final days = last.dateTime.difference(first.dateTime).inDays;
    if (days < 1) return 0.0;

    final weeks = days / 7.0;
    final diffKg = last.weightKg - first.weightKg;

    return diffKg / weeks;
  }

  /// Calculates percentage progress toward goal.
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
