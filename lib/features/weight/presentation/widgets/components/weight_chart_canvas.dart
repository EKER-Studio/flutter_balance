import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational line chart canvas plotting weight entries, target guide line, and axis tick labels.
class WeightChartCanvas extends StatelessWidget {
  final List<WeightEntry> sortedEntries;
  final TimePeriod period;
  final MeasurementUnit unit;
  final double? targetWeight;
  final double chartHeight;

  const WeightChartCanvas({
    super.key,
    required this.sortedEntries,
    required this.period,
    required this.unit,
    required this.targetWeight,
    required this.chartHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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

    final range = maxWeight - minWeight;
    final minPadding = unit == MeasurementUnit.imperial ? 2.0 : 1.0;
    final padding = (range * 0.05).clamp(minPadding, double.infinity);
    final minY = (minWeight - padding).floorToDouble();
    final maxY = (maxWeight + padding).ceilToDouble();

    final latestKg = sortedEntries.last.weightKg;
    final formattedLatest = formatWeight(latestKg, unit);

    return Semantics(
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
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
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
                        period,
                        context,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: unit == MeasurementUnit.imperial ? 55 : 45,
                    getTitlesWidget: (value, meta) {
                      final originalKg = unit == MeasurementUnit.imperial
                          ? lbsToKg(value)
                          : value;
                      final formatted = formatWeight(originalKg, unit);
                      return Text(
                        formatted,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                          color: colorScheme.secondary.withValues(alpha: 0.6),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            labelResolver: (line) => l10n.chartTargetLabel,
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
                  color: colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: sortedEntries.length == 1,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 5,
                        color: colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
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
                  getTooltipColor: (touchedSpot) =>
                      colorScheme.secondaryContainer,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final textStyle = TextStyle(
                        color: colorScheme.onSecondaryContainer,
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
    );
  }

  static String _getPeriodName(TimePeriod p, AppLocalizations l10n) {
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

  static List<FlSpot> _getSpots(
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

  static double _getBottomInterval(List<WeightEntry> sortedEntries) {
    if (sortedEntries.length <= 1) return 1;
    final minutes = sortedEntries.last.dateTime
        .difference(sortedEntries.first.dateTime)
        .inMinutes;
    if (minutes <= 0) return 1;
    return minutes / 4;
  }

  static Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<WeightEntry> sortedEntries,
    TimePeriod period,
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
