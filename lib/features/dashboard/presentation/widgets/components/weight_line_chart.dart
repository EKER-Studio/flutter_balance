import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/theme/app_chart_theme.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A curved line chart of daily-aggregated weight values with touch tooltips.
class WeightLineChart extends StatelessWidget {
  /// The daily-aggregated entries to plot.
  final List<WeightEntry> entries;

  /// The active chart period controlling label density and dot visibility.
  final TimePeriod period;

  /// The measurement unit used to convert and format plotted values.
  final MeasurementUnit measurementUnit;

  /// The user's height in centimeters, used for rendering BMI data if provided.
  final double? heightCm;

  const WeightLineChart({
    super.key,
    required this.entries,
    required this.period,
    required this.measurementUnit,
    this.heightCm,
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

    final showMovingAverage = sortedEntries.length >= 3;
    final smaWeights = showMovingAverage
        ? calculate7DayMovingAverage(sortedEntries)
        : const <double>[];
    final displaySmaWeights = showMovingAverage
        ? smaWeights.map((w) => _displayWeight(w, measurementUnit)).toList()
        : const <double>[];

    final hasHeight = heightCm != null && heightCm! > 0;
    double? normalBmiThresholdDisplay;
    if (hasHeight) {
      final heightM = heightCm! / 100.0;
      final thresholdKg = 24.9 * (heightM * heightM);
      normalBmiThresholdDisplay = _displayWeight(thresholdKg, measurementUnit);
    }

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
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (normalBmiThresholdDisplay != null &&
                  normalBmiThresholdDisplay <= maxY &&
                  normalBmiThresholdDisplay >= minY)
                HorizontalLine(
                  y: normalBmiThresholdDisplay,
                  color: colorScheme.tertiary.withValues(alpha: 0.5),
                  strokeWidth: 1.5,
                  dashArray: [8, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                    ),
                    labelResolver: (_) => l10n.bmiValueShortLabel('24.9'),
                  ),
                ),
            ],
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
                interval: AppChartTheme.bottomInterval(
                  sortedEntries.length,
                  period,
                ),
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
                  final isSmaBar = showMovingAverage && spot.barIndex == 0;
                  final weightDisplay = spot.y;
                  final weightKg = measurementUnit == MeasurementUnit.imperial
                      ? lbsToKg(weightDisplay)
                      : weightDisplay;
                  final prefix = isSmaBar
                      ? '${l10n.movingAverage7dLegend}: '
                      : '';

                  String text =
                      '$prefix${formatWeight(weightKg, measurementUnit)}';
                  if (!isSmaBar && hasHeight) {
                    final heightM = heightCm! / 100.0;
                    final bmi = weightKg / (heightM * heightM);
                    text +=
                        '\n${l10n.bmiValueShortLabel(bmi.toStringAsFixed(1))}';
                  }

                  return LineTooltipItem(
                    text,
                    TextStyle(
                      color: isSmaBar
                          ? colorScheme.tertiary
                          : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            if (showMovingAverage)
              LineChartBarData(
                spots: [
                  for (var index = 0; index < sortedEntries.length; index++)
                    FlSpot(index.toDouble(), displaySmaWeights[index]),
                ],
                isCurved: true,
                curveSmoothness: 0.35,
                color: colorScheme.tertiary,
                barWidth: 2,
                dashArray: [6, 4],
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
              ),
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

    if (AppChartTheme.isDuplicateMonthTick(
      index,
      sortedEntries.map((e) => e.dateTime).toList(),
      period,
    )) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final currentDate = sortedEntries[index].dateTime;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        AppChartTheme.bottomAxisLabel(context, currentDate, period, l10n),
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

  /// Computes the 7-day Simple Moving Average (SMA) for each entry in [sortedEntries].
  ///
  /// For each entry, calculates the arithmetic mean of all measurements within
  /// the inclusive 7-calendar-day window `[entry.dateTime - 6 days, entry.dateTime]`.
  static List<double> calculate7DayMovingAverage(
    List<WeightEntry> sortedEntries,
  ) {
    if (sortedEntries.isEmpty) return const [];
    final result = <double>[];
    for (var i = 0; i < sortedEntries.length; i++) {
      final current = sortedEntries[i];
      final windowStart = DateTime(
        current.dateTime.year,
        current.dateTime.month,
        current.dateTime.day,
      ).subtract(const Duration(days: 6));

      var sum = 0.0;
      var count = 0;
      for (var j = 0; j <= i; j++) {
        final candidateDate = DateTime(
          sortedEntries[j].dateTime.year,
          sortedEntries[j].dateTime.month,
          sortedEntries[j].dateTime.day,
        );
        if (!candidateDate.isBefore(windowStart)) {
          sum += sortedEntries[j].weightKg;
          count++;
        }
      }
      result.add(count > 0 ? sum / count : current.weightKg);
    }
    return result;
  }
}
