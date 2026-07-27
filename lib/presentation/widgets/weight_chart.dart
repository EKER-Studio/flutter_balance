import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

/// A chart widget that displays weight history over time.
class WeightChart extends StatelessWidget {
  /// The list of weight entries to plot.
  final List<WeightEntry> entries;

  /// The currently selected time period for formatting the X-axis.
  final TimePeriod period;

  /// Callback fired when the user selects a new time period.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Optional target weight to display as a horizontal reference line.
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

  /// Optional fixed height for the chart canvas. Defaults to 280px.
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: Center(child: Text(AppLocalizations.of(context).chartEmpty)),
      );
    }

    // Sort entries by date
    final sortedEntries = List<WeightEntry>.from(entries)
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

    // Proportional Y-axis padding: 5% of range, minimum 1 unit.
    final range = maxWeight - minWeight;
    final padding = (range * 0.05).clamp(1.0, double.infinity);
    final minY = (minWeight - padding).floorToDouble();
    final maxY = (maxWeight + padding).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterChips(context),
        const SizedBox(height: 16),
        SizedBox(
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
                        final unitLabel = unit == MeasurementUnit.imperial
                            ? 'lbs'
                            : 'kg';
                        return Text(
                          '${value.toInt()} $unitLabel',
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
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              labelResolver: (line) =>
                                  AppLocalizations.of(context).chartTargetLabel,
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
                      show: true,
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
                        final unitLabel = unit == MeasurementUnit.imperial
                            ? 'lbs'
                            : 'kg';
                        final formattedValue =
                            '${touchedSpot.y.toStringAsFixed(1)} $unitLabel';
                        return LineTooltipItem(formattedValue, textStyle);
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: TimePeriod.values.map((p) {
        return ChoiceChip(
          label: Text(_getPeriodName(p, l10n)),
          selected: period == p,
          onSelected: (selected) {
            if (selected) {
              onPeriodChanged(p);
            }
          },
        );
      }).toList(),
    );
  }

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

  List<FlSpot> _getSpots(
    List<WeightEntry> sortedEntries,
    MeasurementUnit unit,
  ) {
    return sortedEntries.map((e) {
      final y = unit == MeasurementUnit.imperial
          ? kgToLbs(e.weightKg)
          : e.weightKg;
      return FlSpot(e.dateTime.millisecondsSinceEpoch.toDouble(), y);
    }).toList();
  }

  double _getBottomInterval(List<WeightEntry> sortedEntries) {
    if (sortedEntries.length <= 1) return 1;
    final diff =
        sortedEntries.last.dateTime.millisecondsSinceEpoch -
        sortedEntries.first.dateTime.millisecondsSinceEpoch;

    // Divide the time range into ~4-5 segments to not clutter the axis
    if (diff == 0) return 1;
    return diff / 4;
  }

  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<WeightEntry> sortedEntries,
    BuildContext context,
  ) {
    if (sortedEntries.isEmpty) return const SizedBox.shrink();

    final minTime = sortedEntries.first.dateTime.millisecondsSinceEpoch;
    final maxTime = sortedEntries.last.dateTime.millisecondsSinceEpoch;

    // Don't show titles too close to the edges unless they are min/max
    if (value < minTime || value > maxTime) return const SizedBox.shrink();

    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String formattedDate;

    switch (period) {
      case TimePeriod.week:
        formattedDate = DateFormat('EEE').format(date); // Mon, Tue
        break;
      case TimePeriod.month:
        formattedDate = DateFormat('MMMd').format(date); // Oct 12
        break;
      case TimePeriod.year:
      case TimePeriod.all:
        formattedDate = DateFormat('MMM yy').format(date); // Oct 23
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
