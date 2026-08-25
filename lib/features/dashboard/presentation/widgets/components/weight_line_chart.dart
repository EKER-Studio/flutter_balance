import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/theme/app_chart_theme.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A curved line chart of daily-aggregated weight values with touch tooltips.
class WeightLineChart extends StatelessWidget {
  /// The daily-aggregated entries to plot.
  final List<WeightEntry> entries;

  /// The active chart period controlling label density and dot visibility.
  final TimePeriod period;

  /// The measurement unit used to convert and format plotted values.
  final MeasurementUnit measurementUnit;

  const WeightLineChart({
    super.key,
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
    final range = maxWeight - minWeight;
    final padding = (range * 0.1).clamp(0.5, double.infinity);
    final minY = (minWeight - padding).floorToDouble().clamp(
      0.0,
      double.infinity,
    );
    final maxY = (maxWeight + padding).ceilToDouble();
    final yRange = maxY - minY;
    final verticalInterval = yRange <= 4.0
        ? 1.0
        : (yRange <= 8.0 ? 2.0 : (yRange / 4.0).ceilToDouble());
    final isWholeInterval = verticalInterval >= 1.0;

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
          gridData: AppChartTheme.gridData(
            colorScheme: colorScheme,
            horizontalInterval: verticalInterval,
          ),
          borderData: AppChartTheme.borderData(),
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
                reservedSize: 46,
                interval: verticalInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      isWholeInterval
                          ? value.toStringAsFixed(0)
                          : value.toStringAsFixed(1),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              if (event is FlTapUpEvent &&
                  response != null &&
                  response.lineBarSpots != null &&
                  response.lineBarSpots!.isNotEmpty) {
                final spot = response.lineBarSpots!.first;
                final index = spot.spotIndex;
                if (index >= 0 && index < sortedEntries.length) {
                  AppAnalytics.logTodayChartPointTouched();
                }
              }
            },
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
              curveSmoothness: 0.35,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sortedEntries.length == 1,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: sortedEntries.length <= 14 ? 3.5 : 2.5,
                    color: colorScheme.primary,
                    strokeWidth: 1.5,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: AppChartTheme.belowBarGradient(colorScheme.primary),
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
    TimePeriod period,
  ) {
    final index = value.round();
    if (index < 0 ||
        index >= sortedEntries.length ||
        (value - index).abs() > 0.01) {
      return const SizedBox.shrink();
    }

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

  static double _displayWeight(double weightKg, MeasurementUnit unit) {
    return unit == MeasurementUnit.imperial ? kgToLbs(weightKg) : weightKg;
  }

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
