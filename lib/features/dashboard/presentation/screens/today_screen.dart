// The Today tab: daily weight summary, trend chart, tips, and quick add-weight flow.

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/features/dashboard/presentation/widgets/health_summary_card.dart';
import 'package:balance/features/dashboard/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/presentation/widgets/state_message_card.dart';

/// A screen displaying the daily summary, BMI, goal progress, and weight trend.
///
/// The body reflects the current [WeightState]: a shimmer skeleton
/// ([TodayShimmerSkeleton]) while loading, a welcome or error
/// [StateMessageCard] when there are no entries (or a read failure), and
/// otherwise a card stack made of the [HealthSummaryCard], the weight trend
/// chart with period pills, and a daily tip card. The [WeightBloc] feeds all
/// data: `entries` are assumed newest-first, `filteredEntries` (period-filtered
/// per [TimePeriod]) drive the chart, and the error snackbar/retry actions
/// dispatch [SubscribeToWeightChanges].
///
/// A [LayoutBuilder] or [Orientation.landscape] arranges the cards side by side
/// on wide viewports (approx. 40-45% for summary + tips, 55-60% for chart),
/// while portrait viewports preserve the vertical stack.
class TodayScreen extends StatelessWidget {
  /// An optional callback to navigate to settings when the profile icon is pressed.
  final VoidCallback? onNavigateToSettings;

  /// Creates a [TodayScreen].
  const TodayScreen({super.key, this.onNavigateToSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: BlocConsumer<WeightBloc, WeightState>(
        listenWhen: (previous, current) => current is WeightError,
        listener: (context, state) {
          if (state is WeightError && state.entries.isNotEmpty) {
            _showErrorSnackBar(context, state.errorType, l10n);
          }
        },
        builder: (context, state) {
          return _RefreshableTodayBody(
            onRefresh: () => _refreshWeightData(context),
            title: l10n.todayTabTitle,
            child: _buildBody(context, state, l10n),
          );
        },
      ),
      floatingActionButton: BlocBuilder<WeightBloc, WeightState>(
        builder: (context, state) {
          final entries = _entriesFromState(state);
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

  /// Builds the screen body based on the current [WeightState].
  ///
  /// Returns a shimmer skeleton while loading, error or welcome [StateMessageCard]s, or the responsive card stack.
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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, settings) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600 || isLandscape;

            final Widget cardStack;
            if (isWide) {
              cardStack = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state is WeightError) ...[
                          _InlineErrorBanner(errorType: state.errorType),
                          const SizedBox(height: 16),
                        ],
                        HealthSummaryCard(
                          latestWeightKg: latestEntry.weightKg,
                          lastUpdated: latestEntry.dateTime,
                        ),
                        const SizedBox(height: 16),
                        const _DailyTipCard(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WeightTrendChartCard(
                          entries: filteredEntries,
                          period: state.timePeriod,
                          measurementUnit: settings.measurementUnit,
                          onPeriodChanged: (period) {
                            context.read<WeightBloc>().add(
                              ChangeChartFilter(period),
                            );
                          },
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              cardStack = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state is WeightError) ...[
                    _InlineErrorBanner(errorType: state.errorType),
                    const SizedBox(height: 16),
                  ],
                  HealthSummaryCard(
                    latestWeightKg: latestEntry.weightKg,
                    lastUpdated: latestEntry.dateTime,
                  ),
                  const SizedBox(height: 16),
                  _WeightTrendChartCard(
                    entries: filteredEntries,
                    period: state.timePeriod,
                    measurementUnit: settings.measurementUnit,
                    onPeriodChanged: (period) {
                      context.read<WeightBloc>().add(ChangeChartFilter(period));
                    },
                  ),
                  const SizedBox(height: 16),
                  const _DailyTipCard(),
                  const SizedBox(height: 120),
                ],
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1200 : 600),
                child: cardStack,
              ),
            );
          },
        );
      },
    );
  }

  /// Extracts the full [WeightEntry] list from the given [state].
  static List<WeightEntry> _entriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
  }

  /// Extracts the period-filtered [WeightEntry] list from the given [state].
  static List<WeightEntry> _filteredEntriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final filteredEntries) => filteredEntries,
      WeightError(:final filteredEntries) => filteredEntries,
      _ => <WeightEntry>[],
    };
  }

  /// Dispatches [RefreshWeightData] and waits up to two seconds for the refresh to settle.
  Future<void> _refreshWeightData(BuildContext context) async {
    final bloc = context.read<WeightBloc>();
    bloc.add(const RefreshWeightData());
    await bloc.stream
        .firstWhere((state) => state is WeightLoaded || state is WeightError)
        .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
  }

  /// Shows a localized error snackbar with a retry action.
  void _showErrorSnackBar(
    BuildContext context,
    WeightErrorType errorType,
    AppLocalizations l10n,
  ) {
    final message = errorType.localizedMessage(l10n);
    AppSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
      action: SnackBarAction(
        label: l10n.retry,
        onPressed: () {
          context.read<WeightBloc>().add(const SubscribeToWeightChanges());
        },
      ),
    );
  }

  /// Opens the [AddWeightSheet] dialog to allow the user to add a new weight entry.
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

/// A widget that wraps its [child] in a pull-to-refresh indicator backed by [onRefresh].
class _RefreshableTodayBody extends StatelessWidget {
  /// A callback invoked when the user pulls to refresh.
  final Future<void> Function() onRefresh;

  /// The scrollable content subtree.
  final Widget child;

  /// The title for the sliver app bar.
  final String title;

  /// Creates a [_RefreshableTodayBody].
  const _RefreshableTodayBody({
    required this.onRefresh,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          AppTopBar(title: title),
          SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(
              child: ClampedLayout(
                maxWidth: isLandscape ? 1200 : 600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card containing the weight trend line chart and its period filter.
class _WeightTrendChartCard extends StatelessWidget {
  /// The entries to plot, pre-filtered by [period].
  final List<WeightEntry> entries;

  /// The currently selected chart time period.
  final TimePeriod period;

  /// The measurement unit used to format the plotted values.
  final MeasurementUnit measurementUnit;

  /// A callback invoked when a new chart period is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [_WeightTrendChartCard].
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.weightTrend,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _WeightDeltaChip(
                  entries: entries,
                  measurementUnit: measurementUnit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ChartPeriodFilters(
              period: period,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
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
                      period: period,
                      measurementUnit: measurementUnit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centered row of buttons for selecting the chart period.
class _ChartPeriodFilters extends StatelessWidget {
  /// The currently selected period.
  final TimePeriod period;

  /// A callback invoked when a pill is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [_ChartPeriodFilters].
  const _ChartPeriodFilters({
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final periods = [TimePeriod.week, TimePeriod.month, TimePeriod.year];

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.asMap().entries.map((entry) {
          final index = entry.key;
          final candidate = entry.value;
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: _PeriodButton(
              label: _periodLabel(candidate, l10n),
              selected: period == candidate,
              onPressed: () => onPeriodChanged(candidate),
            ),
          );
        }).toList(),
      ),
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

/// A standalone button for selecting one chart period.
class _PeriodButton extends StatelessWidget {
  /// The localized period label.
  final String label;

  /// Whether this period is active.
  final bool selected;

  /// Invoked when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a [_PeriodButton].
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? const Color(0xFFA8C7FA) : null,
        foregroundColor: selected
            ? const Color(0xFF00325B)
            : colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A tonal summary of the weight change in the active chart period.
class _WeightDeltaChip extends StatelessWidget {
  /// The entries included in the active chart period.
  final List<WeightEntry> entries;

  /// The unit used to format the displayed delta.
  final MeasurementUnit measurementUnit;

  /// Creates a [_WeightDeltaChip].
  const _WeightDeltaChip({
    required this.entries,
    required this.measurementUnit,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final deltaKg = sortedEntries.length < 2
        ? 0.0
        : sortedEntries.last.weightKg - sortedEntries.first.weightKg;
    final delta = _WeightLineChart._displayWeight(deltaKg, measurementUnit);
    final isLoss = delta < 0;
    final isGain = delta > 0;
    final backgroundColor = isLoss
        ? const Color(0xFF14291E)
        : isGain
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final foregroundColor = isLoss
        ? const Color(0xFF7CE38B)
        : isGain
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isLoss
        ? Icons.trending_down_rounded
        : isGain
        ? Icons.trending_up_rounded
        : Icons.remove_rounded;
    final unitLabel = measurementUnit == MeasurementUnit.imperial ? 'lb' : 'kg';
    final prefix = isGain ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            '$prefix${delta.toStringAsFixed(1)} $unitLabel',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A curved line chart of daily-aggregated weight values with touch tooltips.
///
/// The X axis is the entry index and the Y axis holds weights converted to
/// [measurementUnit]; tooltips convert the plotted value back to kilograms for
/// formatting.
class _WeightLineChart extends StatelessWidget {
  /// The daily-aggregated entries to plot.
  final List<WeightEntry> entries;

  /// The active chart period controlling label density and dot visibility.
  final TimePeriod period;

  /// The measurement unit used to convert and format plotted values.
  final MeasurementUnit measurementUnit;

  /// Creates a [_WeightLineChart].
  const _WeightLineChart({
    required this.entries,
    required this.period,
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
    final verticalInterval = _verticalInterval(minY, maxY);

    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label:
          '${l10n.weightTrend}, ${l10n.weightTrendChartSemantics(entries.length)}',
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(0, sortedEntries.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: verticalInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colorScheme.surfaceContainerHighest,
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
                interval: _bottomInterval(sortedEntries.length, period),
                getTitlesWidget: (value, meta) {
                  return _buildBottomTitle(
                    context,
                    value,
                    sortedEntries,
                    period,
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: verticalInterval,
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
                show: period == TimePeriod.week,
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
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom axis label for the entry at [value].
  ///
  /// Renders a localized date label for valid index ticks while suppressing
  /// duplicate month names on yearly and multi-year spans.
  Widget _buildBottomTitle(
    BuildContext context,
    double value,
    List<WeightEntry> sortedEntries,
    TimePeriod period,
  ) {
    final index = value.round();
    if (index < 0 ||
        index >= sortedEntries.length ||
        (value - index).abs() > 0.01) {
      return const SizedBox.shrink();
    }

    // Suppress duplicate month labels on consecutive tick intervals
    if (_isDuplicateMonthTick(index, sortedEntries, period)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final currentDate = sortedEntries[index].dateTime;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _bottomAxisLabel(context, currentDate, period, l10n),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFamily: 'Roboto',
          fontSize: 12,
        ),
      ),
    );
  }

  /// Checks if the tick at [index] shares the same month and year as the previous sampled tick.
  static bool _isDuplicateMonthTick(
    int index,
    List<WeightEntry> sortedEntries,
    TimePeriod period,
  ) {
    if (period != TimePeriod.year && period != TimePeriod.all) {
      return false;
    }

    final step = _bottomInterval(sortedEntries.length, period).toInt();
    final prevIndex = index - step;
    if (prevIndex < 0 || prevIndex >= sortedEntries.length) {
      return false;
    }

    final currentDate = sortedEntries[index].dateTime;
    final prevDate = sortedEntries[prevIndex].dateTime;

    return prevDate.year == currentDate.year &&
        prevDate.month == currentDate.month;
  }

  /// Converts a weight in kilograms to the display [unit].
  static double _displayWeight(double weightKg, MeasurementUnit unit) {
    return unit == MeasurementUnit.imperial ? kgToLbs(weightKg) : weightKg;
  }

  /// Rounds [value] down to the nearest multiple of 0.5.
  static double _roundDownToHalf(double value) => (value * 2).floor() / 2;

  /// Rounds [value] up to the nearest multiple of 0.5.
  static double _roundUpToHalf(double value) => (value * 2).ceil() / 2;

  /// Chooses a period-specific tick interval with no more than six labels.
  static double _bottomInterval(int length, TimePeriod period) {
    if (length <= 1) {
      return 1;
    }
    final targetIntervals = switch (period) {
      TimePeriod.week => 6,
      TimePeriod.month => 4,
      TimePeriod.year || TimePeriod.all => 5,
    };
    return math.max(1, ((length - 1) / targetIntervals).ceil()).toDouble();
  }

  /// Chooses a readable interval that keeps horizontal grid lines sparse.
  static double _verticalInterval(double minY, double maxY) {
    final rawInterval = (maxY - minY) / 4;
    for (final interval in [0.5, 1.0, 2.0, 5.0, 10.0]) {
      if (rawInterval <= interval) {
        return interval;
      }
    }
    return 10;
  }

  String _bottomAxisLabel(
    BuildContext context,
    DateTime date,
    TimePeriod period,
    AppLocalizations l10n,
  ) {
    return switch (period) {
      TimePeriod.week => _weekdayLabel(date.weekday, l10n),
      TimePeriod.month => date.day.toString(),
      TimePeriod.year || TimePeriod.all => _monthLabel(context, date),
    };
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

  String _monthLabel(BuildContext context, DateTime date) =>
      DateFormat.MMM(Localizations.localeOf(context).toString()).format(date);
}

/// A card with a rotating daily weight-logging tip.
class _DailyTipCard extends StatelessWidget {
  /// Creates a [_DailyTipCard].
  const _DailyTipCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: '${l10n.dailyTipTitle}: ${l10n.dailyTipText}',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.surfaceContainerHigh),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.dailyTipTitle}: ${l10n.dailyTipText}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An inline banner shown above the card stack when the current state carries an error.
///
/// Offers a retry action.
class _InlineErrorBanner extends StatelessWidget {
  /// The typed error to surface to the user.
  final WeightErrorType errorType;

  /// Creates an [_InlineErrorBanner].
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
