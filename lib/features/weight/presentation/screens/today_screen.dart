import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/state_message_card.dart';

/// Tab 1: Today Screen displaying daily summary, BMI, goal progress, and weight trend.
class TodayScreen extends StatelessWidget {
  /// Optional callback to navigate to Settings when profile icon is pressed.
  final VoidCallback? onNavigateToSettings;

  /// Creates a [TodayScreen] with optional navigation callbacks.
  const TodayScreen({super.key, this.onNavigateToSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: _TodayAppBar(onProfilePressed: onNavigateToSettings),
      body: SafeArea(
        child: BlocConsumer<WeightBloc, WeightState>(
          listenWhen: (previous, current) => current is WeightError,
          listener: (context, state) {
            if (state is WeightError && state.entries.isNotEmpty) {
              _showErrorSnackBar(context, state.errorType, l10n);
            }
          },
          builder: (context, state) {
            return _RefreshableTodayBody(
              onRefresh: () => _refreshWeightData(context),
              child: _buildBody(context, state, l10n),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<WeightBloc, WeightState>(
        builder: (context, state) {
          final entries = _entriesFromState(state);
          if (entries.isEmpty ||
              state is WeightInitial ||
              state is WeightLoading) {
            return const SizedBox.shrink();
          }
          return _AddWeightFAB(onPressed: () => _showAddWeightSheet(context));
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WeightState state,
    AppLocalizations l10n,
  ) {
    if (state is WeightInitial || state is WeightLoading) {
      return const TodayShimmerSkeleton();
    }

    final entries = _entriesFromState(state);
    if (state is WeightError && entries.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return StateMessageCard(
        icon: Icons.error_outline,
        iconColor: colorScheme.error,
        iconContainerColor: colorScheme.errorContainer,
        title: l10n.errorReadFailed,
        subtitle: state.errorType.localizedMessage(l10n),
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
        onButtonPressed: () => _showAddWeightSheet(context),
      );
    }

    final filteredEntries = _filteredEntriesFromState(state);
    final latestEntry = entries.first;

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settings) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is WeightError) ...[
              _InlineErrorBanner(errorType: state.errorType),
              const SizedBox(height: 16),
            ],
            _WeightSummaryCard(
              latestEntry: latestEntry,
              entries: entries,
              settings: settings,
            ),
            const SizedBox(height: 12),
            _WeightTrendChartCard(
              entries: filteredEntries,
              period: state.timePeriod,
              measurementUnit: settings.measurementUnit,
              onPeriodChanged: (period) {
                context.read<WeightBloc>().add(ChangeChartFilter(period));
              },
            ),
            const SizedBox(height: 12),
            const _DailyTipCard(),
            const SizedBox(height: 80),
          ],
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

  Future<void> _refreshWeightData(BuildContext context) async {
    final bloc = context.read<WeightBloc>();
    bloc.add(const RefreshWeightData());
    await bloc.stream
        .firstWhere((state) => state is WeightLoaded || state is WeightError)
        .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
  }

  void _showErrorSnackBar(
    BuildContext context,
    WeightErrorType errorType,
    AppLocalizations l10n,
  ) {
    final message = errorType.localizedMessage(l10n);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: l10n.retry,
          onPressed: () {
            context.read<WeightBloc>().add(const SubscribeToWeightChanges());
          },
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddWeightSheet());
  }
}

class _RefreshableTodayBody extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshableTodayBody({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ClampedLayout(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}

class _TodayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfilePressed;

  const _TodayAppBar({this.onProfilePressed});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      toolbarHeight: 64,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_weight, color: colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            l10n.todayTabTitle,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: colorScheme.onSurface,
          ),
          tooltip: l10n.settingsTitle,
          onPressed: onProfilePressed,
        ),
      ],
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  final WeightEntry latestEntry;
  final List<WeightEntry> entries;
  final AppSettingsState settings;

  const _WeightSummaryCard({
    required this.latestEntry,
    required this.entries,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final latestWeight = formatWeight(
      latestEntry.weightKg,
      settings.measurementUnit,
    );
    final weightParts = latestWeight.split(' ');
    final weightValue = weightParts.first;
    final weightUnit = weightParts.length > 1
        ? weightParts.last
        : unitLabelFor(settings.measurementUnit);
    final bmi = settings.calculateBmi(latestEntry.weightKg);
    final bmiCategory = settings.getBmiCategory(bmi);
    final bmiStatus = bmiCategory.localizedName(l10n);
    final remaining = _remainingToTarget(
      latestEntry.weightKg,
      settings.targetWeight,
    );
    final remainingLabel = settings.targetWeight == null
        ? l10n.notSet
        : formatWeight(remaining, settings.measurementUnit);

    return Semantics(
      container: true,
      label: l10n.weightSummarySemanticsLabel(
        latestWeight,
        bmiStatus,
        remainingLabel,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -16,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.lastMeasurementLabel,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    weightValue,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.displayMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  weightUnit,
                                  style: textTheme.titleLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatMeasurementTime(
                                latestEntry.dateTime,
                                l10n,
                              ),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BmiBadge(
                        bmi: bmi,
                        status: bmiStatus,
                        category: bmiCategory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.goalWeightLabel(
                            settings.targetWeight == null
                                ? l10n.notSet
                                : formatWeight(
                                    settings.targetWeight!,
                                    settings.measurementUnit,
                                  ),
                          ),
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          l10n.remainingWeightLabel(remainingLabel),
                          textAlign: TextAlign.end,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: _goalProgress(
                        entries,
                        latestEntry.weightKg,
                        settings.targetWeight,
                      ),
                      minHeight: 8,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _remainingToTarget(double currentWeight, double? targetWeight) {
    if (targetWeight == null) {
      return 0;
    }
    return (currentWeight - targetWeight).abs();
  }

  static double _goalProgress(
    List<WeightEntry> entries,
    double currentWeight,
    double? targetWeight,
  ) {
    if (targetWeight == null || entries.isEmpty) {
      return 0;
    }
    final oldestWeight = entries.last.weightKg;
    final denominator = (oldestWeight - targetWeight).abs();
    if (denominator == 0) {
      return currentWeight == targetWeight ? 1 : 0;
    }
    final numerator = targetWeight < oldestWeight
        ? oldestWeight - currentWeight
        : currentWeight - oldestWeight;
    return (numerator / denominator).clamp(0.0, 1.0);
  }
}

class _BmiBadge extends StatelessWidget {
  final double bmi;
  final String status;
  final BmiCategory category;

  const _BmiBadge({
    required this.bmi,
    required this.status,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minWidth: 108),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statusIcon(category),
                color: colorScheme.primary,
                size: 16,
                fill: 1,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.bmiValueShortLabel(bmi.toStringAsFixed(1)),
            textAlign: TextAlign.end,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(BmiCategory category) {
    return switch (category) {
      BmiCategory.normal => Icons.check_circle,
      BmiCategory.underweight ||
      BmiCategory.overweight ||
      BmiCategory.obese => Icons.info,
    };
  }
}

class _WeightTrendChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final TimePeriod period;
  final MeasurementUnit measurementUnit;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const _WeightTrendChartCard({
    required this.entries,
    required this.period,
    required this.measurementUnit,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weightTrend,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ChartPeriodFilters(
                period: period,
                onPeriodChanged: onPeriodChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      l10n.chartEmpty,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _WeightLineChart(
                    entries: entries,
                    measurementUnit: measurementUnit,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartPeriodFilters extends StatelessWidget {
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const _ChartPeriodFilters({
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periods = [TimePeriod.week, TimePeriod.month, TimePeriod.year];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: periods.map((candidate) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: _PeriodPill(
            label: _periodLabel(candidate, l10n),
            selected: period == candidate,
            onPressed: () => onPeriodChanged(candidate),
          ),
        );
      }).toList(),
    );
  }

  String _periodLabel(TimePeriod period, AppLocalizations l10n) {
    return switch (period) {
      TimePeriod.week => l10n.week,
      TimePeriod.month => l10n.month,
      TimePeriod.year => l10n.year,
      TimePeriod.all => l10n.all,
    };
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9999),
        hoverColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        focusColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final MeasurementUnit measurementUnit;

  const _WeightLineChart({
    required this.entries,
    required this.measurementUnit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final displayWeights = sortedEntries
        .map((entry) => _displayWeight(entry.weightKg, measurementUnit))
        .toList();
    final minWeight = displayWeights.reduce(math.min);
    final maxWeight = displayWeights.reduce(math.max);
    final minY = _roundDownToHalf(minWeight - 0.5);
    final maxY = _roundUpToHalf(maxWeight + 0.5);

    return Semantics(
      container: true,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(0, sortedEntries.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.outlineVariant,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _bottomInterval(sortedEntries.length),
                getTitlesWidget: (value, meta) {
                  return _buildBottomTitle(context, value, sortedEntries);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Roboto',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(strokeWidth: 0),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      );
                    },
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.secondaryContainer,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final weight = measurementUnit == MeasurementUnit.imperial
                      ? lbsToKg(spot.y)
                      : spot.y;
                  return LineTooltipItem(
                    formatWeight(weight, measurementUnit),
                    TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var index = 0; index < sortedEntries.length; index++)
                  FlSpot(index.toDouble(), displayWeights[index]),
              ],
              isCurved: true,
              curveSmoothness: 0.4,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTitle(
    BuildContext context,
    double value,
    List<WeightEntry> sortedEntries,
  ) {
    final index = value.round();
    if (index < 0 ||
        index >= sortedEntries.length ||
        (value - index).abs() > 0.01) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _weekdayLabel(sortedEntries[index].dateTime.weekday, l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFamily: 'Roboto',
          fontSize: 12,
        ),
      ),
    );
  }

  static double _displayWeight(double weightKg, MeasurementUnit unit) {
    return unit == MeasurementUnit.imperial ? kgToLbs(weightKg) : weightKg;
  }

  static double _roundDownToHalf(double value) => (value * 2).floor() / 2;

  static double _roundUpToHalf(double value) => (value * 2).ceil() / 2;

  static double _bottomInterval(int length) {
    if (length <= 1) {
      return 1;
    }
    return math.max(1, ((length - 1) / 4).ceil()).toDouble();
  }

  String _weekdayLabel(int weekday, AppLocalizations l10n) {
    return switch (weekday) {
      DateTime.monday => l10n.weekdayShortMonday,
      DateTime.tuesday => l10n.weekdayShortTuesday,
      DateTime.wednesday => l10n.weekdayShortWednesday,
      DateTime.thursday => l10n.weekdayShortThursday,
      DateTime.friday => l10n.weekdayShortFriday,
      DateTime.saturday => l10n.weekdayShortSaturday,
      DateTime.sunday => l10n.weekdayShortSunday,
      _ => l10n.weekdayShortMonday,
    };
  }
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.dailyTipText,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final WeightErrorType errorType;

  const _InlineErrorBanner({required this.errorType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final errorText = errorType.localizedMessage(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<WeightBloc>().add(const SubscribeToWeightChanges());
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _AddWeightFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddWeightFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: l10n.addWeightSemanticsLabel,
      child: FloatingActionButton.large(
        onPressed: onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _formatMeasurementTime(DateTime dateTime, AppLocalizations l10n) {
  final time = DateFormat.Hm().format(dateTime);
  final now = DateTime.now();
  final isToday =
      dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day;

  if (isToday) {
    return l10n.todayAtTime(time);
  }
  return l10n.lastUpdatedDate(DateFormat.yMMMd().add_Hm().format(dateTime));
}
