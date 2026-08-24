import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/presentation/theme/app_chart_theme.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational line chart plotting BMI points with touch tooltips and formatted date axis ticks.
class BmiLineChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double heightCm;
  final TimePeriod period;

  const BmiLineChart({
    super.key,
    required this.entries,
    required this.heightCm,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final hMeters = heightCm / 100.0;
    final hSquared = hMeters * hMeters;

    final spots = <FlSpot>[];
    double minBmi = double.infinity;
    double maxBmi = double.negativeInfinity;

    for (var i = 0; i < sortedEntries.length; i++) {
      final bmi = sortedEntries[i].weightKg / hSquared;
      if (bmi < minBmi) minBmi = bmi;
      if (bmi > maxBmi) maxBmi = bmi;
      spots.add(FlSpot(i.toDouble(), bmi));
    }

    final range = maxBmi - minBmi;
    final padding = (range * 0.1).clamp(0.5, double.infinity);
    final minY = (minBmi - padding).floorToDouble().clamp(10.0, 100.0);
    final maxY = (maxBmi + padding).ceilToDouble();

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(0, sortedEntries.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: AppChartTheme.gridData(
            colorScheme: cs,
            horizontalInterval: 2,
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
                getTitlesWidget: (value, meta) =>
                    _buildBottomTitle(context, value, sortedEntries, period),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
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
                  final entry = sortedEntries[index];
                  AppAnalytics.logStatisticsBmiPointTouched(
                    date: entry.dateTime.toIso8601String(),
                    bmi: spot.y,
                  );
                }
              }
            },
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  const FlLine(strokeWidth: 0),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 6,
                          color: cs.primary,
                          strokeWidth: 2,
                          strokeColor: cs.surface,
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => cs.secondaryContainer,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                return LineTooltipItem(
                  'BMI ${spot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: cs.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: sortedEntries.length == 1,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: cs.primary,
                      strokeWidth: 2,
                      strokeColor: cs.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: AppChartTheme.belowBarGradient(cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _bottomInterval(int length, TimePeriod period) {
    if (length <= 1) return 1;
    final targetIntervals = switch (period) {
      TimePeriod.week => 6,
      TimePeriod.month => 4,
      TimePeriod.year || TimePeriod.all => 5,
    };
    return math.max(1, ((length - 1) / targetIntervals).ceil()).toDouble();
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
    final date = sortedEntries[index].dateTime;

    final label = switch (period) {
      TimePeriod.week => _weekdayLabel(date.weekday, l10n),
      TimePeriod.month => date.day.toString(),
      TimePeriod.year || TimePeriod.all => DateFormat.MMM(
        Localizations.localeOf(context).toString(),
      ).format(date),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }

  static bool _isDuplicateMonthTick(
    int index,
    List<WeightEntry> sortedEntries,
    TimePeriod period,
  ) {
    if (period != TimePeriod.year && period != TimePeriod.all) return false;
    final step = _bottomInterval(sortedEntries.length, period).toInt();
    final prevIndex = index - step;
    if (prevIndex < 0 || prevIndex >= sortedEntries.length) return false;
    final currentDate = sortedEntries[index].dateTime;
    final prevDate = sortedEntries[prevIndex].dateTime;
    return prevDate.year == currentDate.year &&
        prevDate.month == currentDate.month;
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
