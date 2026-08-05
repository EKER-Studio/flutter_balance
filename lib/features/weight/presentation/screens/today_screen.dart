import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/health_summary_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/app_top_bar.dart';
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

  /// Builds the screen body for the current [state]: shimmer skeleton while
  /// loading, error/welcome [StateMessageCard]s, or the responsive card stack.
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            final Widget cardStack;
            if (isWide) {
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
                  const SizedBox(height: 80),
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
                  const SizedBox(height: 80),
                ],
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: cardStack,
              ),
            );
          },
        );
      },
    );
  }

  /// Extracts the full entry list from the current [WeightState].
  static List<WeightEntry> _entriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
  }

  /// Extracts the period-filtered entry list from the current [WeightState].
  static List<WeightEntry> _filteredEntriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final filteredEntries) => filteredEntries,
      WeightError(:final filteredEntries) => filteredEntries,
      _ => <WeightEntry>[],
    };
  }

  /// Dispatches [RefreshWeightData] and waits up to two seconds for the
  /// refresh to settle.
  Future<void> _refreshWeightData(BuildContext context) async {
    final bloc = context.read<WeightBloc>();
    bloc.add(const RefreshWeightData());
    await bloc.stream
        .firstWhere((state) => state is WeightLoaded || state is WeightError)
        .timeout(const Duration(seconds: 2), onTimeout: () => bloc.state);
  }

  /// Shows a localized error [SnackBar] with a retry action.
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

  /// Opens the [AddWeightSheet] dialog.
  void _showAddWeightSheet(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddWeightSheet());
  }
}

/// Wraps [child] in a pull-to-refresh [RefreshIndicator] backed by [onRefresh].
class _RefreshableTodayBody extends StatelessWidget {
  /// Callback invoked when the user pulls to refresh.
  final Future<void> Function() onRefresh;

  /// The scrollable content subtree.
  final Widget child;

  /// The title for the sliver app bar.
  final String title;

  /// Creates a [_RefreshableTodayBody] with [onRefresh], [child], and [title].
  const _RefreshableTodayBody({
    required this.onRefresh,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
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

/// Card containing the weight trend line chart and its period filter pills.
class _WeightTrendChartCard extends StatelessWidget {
  /// Entries to plot, pre-filtered by [period].
  final List<WeightEntry> entries;

  /// The currently selected chart time period.
  final TimePeriod period;

  /// The measurement unit used to format the plotted values.
  final MeasurementUnit measurementUnit;

  /// Callback invoked when a new chart period is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [_WeightTrendChartCard] with the given properties.
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

/// Row of selectable period pills (week, month, year) for the chart.
class _ChartPeriodFilters extends StatelessWidget {
  /// The currently selected period.
  final TimePeriod period;

  /// Callback invoked when a pill is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [_ChartPeriodFilters] with [period] and [onPeriodChanged].
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

/// Single pill-shaped period selector button.
class _PeriodPill extends StatelessWidget {
  /// The localized label of the period.
  final String label;

  /// Whether this pill represents the active period.
  final bool selected;

  /// Callback invoked when the pill is tapped.
  final VoidCallback onPressed;

  /// Creates a [_PeriodPill] with [label], [selected], and [onPressed].
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
      ),
    );
  }
}

/// Curved line chart of daily-aggregated weight values with touch tooltips.
class _WeightLineChart extends StatelessWidget {
  /// The daily-aggregated entries to plot.
  final List<WeightEntry> entries;

  /// The measurement unit used to convert and format plotted values.
  final MeasurementUnit measurementUnit;

  /// Creates a [_WeightLineChart] with [entries] and [measurementUnit].
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

/// Card with a rotating daily weight-logging tip.
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dailyTipTitle,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.dailyTipText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
}

/// Inline banner shown above the card stack when the current state carries an
/// error, offering a retry action.
class _InlineErrorBanner extends StatelessWidget {
  /// The typed error to surface to the user.
  final WeightErrorType errorType;

  /// Creates an [_InlineErrorBanner] for [errorType].
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
