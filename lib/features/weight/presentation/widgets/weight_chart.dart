import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';

/// A chart widget that displays weight history over time.
///
/// Plots [entries] on a time-based X-axis, converts values into the active
/// measurement unit, and renders the optional [targetWeight] as a dashed
/// reference line.
class WeightChart extends StatelessWidget {
  /// The list of weight entries to plot.
  final List<WeightEntry> entries;

  /// The currently selected time period for formatting the X-axis.
  final TimePeriod period;

  /// A callback fired when the user selects a new time period.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// An optional target weight to display as a horizontal reference line.
  final double? targetWeight;

  /// Creates a [WeightChart] with [entries], [period], and [onPeriodChanged].
  const WeightChart({
    super.key,
    required this.entries,
    required this.period,
    required this.onPeriodChanged,
    this.chartHeight = 280,
    this.targetWeight,
  });

  /// An optional fixed height for the chart canvas. Defaults to 280px.
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: Center(child: Text(l10n.chartEmpty)),
      );
    }

    // Sort entries by date (repo returns descending, reverse for ascending chart)
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;
    final weightsInDisplayUnit = sortedEntries
        .map(
          (e) => unit == MeasurementUnit.imperial
              ? kgToLbs(e.weightKg)
              : e.weightKg,
        )
        .toList();
    final minWeight = weightsInDisplayUnit.reduce((a, b) => a < b ? a : b);
    final maxWeight = weightsInDisplayUnit.reduce((a, b) => a > b ? a : b);
    final targetY = targetWeight == null
        ? null
        : (unit == MeasurementUnit.imperial
              ? kgToLbs(targetWeight!)
              : targetWeight!);
    final safeTargetY = targetY ?? minWeight;

    // Proportional Y-axis padding: 5% of range, minimum unit-aware floor.
    final range = maxWeight - minWeight;
    final minPadding = unit == MeasurementUnit.imperial ? 2.0 : 1.0;
    final padding = (range * 0.05).clamp(minPadding, double.infinity);
    final minY = (minWeight - padding).floorToDouble();
    final maxY = (maxWeight + padding).ceilToDouble();

    final latestKg = sortedEntries.last.weightKg;
    final formattedLatest = formatWeight(latestKg, unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterChips(context),
        const SizedBox(height: 16),
        Semantics(
          container: true,
          label: l10n.chartSemanticsTitle(
            _getPeriodName(period, l10n),
            formattedLatest,
          ),
          child: SizedBox(
            height: chartHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
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
                        interval: _getBottomInterval(sortedEntries),
                        getTitlesWidget: (value, meta) {
                          return _buildBottomTitle(
                            value,
                            meta,
                            sortedEntries,
                            context,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          final originalKg = unit == MeasurementUnit.imperial
                              ? lbsToKg(value)
                              : value;
                          final formatted = formatWeight(originalKg, unit);
                          return Text(
                            formatted,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: targetY != null
                      ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: safeTargetY,
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.6),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                labelResolver: (line) => AppLocalizations.of(
                                  context,
                                ).chartTargetLabel,
                                alignment: Alignment.topRight,
                              ),
                            ),
                          ],
                        )
                      : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getSpots(sortedEntries, unit),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: period == TimePeriod.week,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Theme.of(context).colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(context).colorScheme.secondaryContainer,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final textStyle = TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          );
                          final originalKg = unit == MeasurementUnit.imperial
                              ? lbsToKg(touchedSpot.y)
                              : touchedSpot.y;
                          final formattedValue = formatWeight(originalKg, unit);
                          return LineTooltipItem(formattedValue, textStyle);
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the row of period filter ChoiceChips above the chart.
  Widget _buildFilterChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: TimePeriod.values.map((p) {
        final label = _getPeriodName(p, l10n);
        final isSelected = period == p;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: '$label ${l10n.chartSemanticsFilter}',
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPeriodChanged(p);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Returns the localized label for [p].
  String _getPeriodName(TimePeriod p, AppLocalizations l10n) {
    switch (p) {
      case TimePeriod.week:
        return l10n.week;
      case TimePeriod.month:
        return l10n.month;
      case TimePeriod.year:
        return l10n.year;
      case TimePeriod.all:
        return l10n.all;
    }
  }

  /// Maps [sortedEntries] to [FlSpot] instances with minutes-since-first as X
  /// and the weight converted into [unit] as Y.
  List<FlSpot> _getSpots(
    List<WeightEntry> sortedEntries,
    MeasurementUnit unit,
  ) {
    if (sortedEntries.isEmpty) return [];

    final firstDate = sortedEntries.first.dateTime;

    return sortedEntries.map((entry) {
      final y = unit == MeasurementUnit.imperial
          ? kgToLbs(entry.weightKg)
          : entry.weightKg;

      final x = entry.dateTime.difference(firstDate).inMinutes.toDouble();

      return FlSpot(x, y);
    }).toList();
  }

  /// Computes the X-axis label interval as a quarter of the visible span.
  double _getBottomInterval(List<WeightEntry> sortedEntries) {
    if (sortedEntries.length <= 1) {
      return 1;
    }

    final minutes = sortedEntries.last.dateTime
        .difference(sortedEntries.first.dateTime)
        .inMinutes;

    if (minutes <= 0) {
      return 1;
    }

    return minutes / 4;
  }

  /// Builds the bottom axis label for the date at the given [value],
  /// formatted according to the current [period].
  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<WeightEntry> sortedEntries,
    BuildContext context,
  ) {
    if (sortedEntries.isEmpty) return const SizedBox.shrink();

    final firstDate = sortedEntries.first.dateTime;
    final lastDate = sortedEntries.last.dateTime;

    final maxMinutes = lastDate.difference(firstDate).inMinutes.toDouble();

    if (value < 0 || value > maxMinutes) {
      return const SizedBox.shrink();
    }

    final date = firstDate.add(Duration(minutes: value.round()));
    String formattedDate;

    switch (period) {
      case TimePeriod.week:
        formattedDate = DateFormat('EEE').format(date);
        break;
      case TimePeriod.month:
        formattedDate = DateFormat('MMMd').format(date);
        break;
      case TimePeriod.year:
      case TimePeriod.all:
        formattedDate = DateFormat('MMM yy').format(date);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        formattedDate,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
