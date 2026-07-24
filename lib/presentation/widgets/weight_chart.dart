import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';

/// A chart widget that displays weight history over time.
class WeightChart extends StatelessWidget {
  /// The list of weight entries to plot.
  final List<WeightEntry> entries;

  /// The currently selected time period for formatting the X-axis.
  final TimePeriod period;

  /// Callback fired when the user selects a new time period.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [WeightChart] with [entries], [period], and [onPeriodChanged].
  const WeightChart({
    super.key,
    required this.entries,
    required this.period,
    required this.onPeriodChanged,
    this.chartHeight = 280,
  });

  /// Optional fixed height for the chart canvas. Defaults to 280px.
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: const Center(child: Text('Not enough data to display chart.')),
      );
    }

    // Sort entries by date
    final sortedEntries = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final minWeight = sortedEntries
        .map((e) => e.weightKg)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = sortedEntries
        .map((e) => e.weightKg)
        .reduce((a, b) => a > b ? a : b);

    // Add some padding to Y axis
    final minY = (minWeight - 2).floorToDouble();
    final maxY = (maxWeight + 2).ceilToDouble();

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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(sortedEntries),
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
                        return LineTooltipItem(
                          '${touchedSpot.y} kg',
                          textStyle,
                        );
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
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: TimePeriod.values.map((p) {
        return ChoiceChip(
          label: Text(_getPeriodName(p)),
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

  String _getPeriodName(TimePeriod p) {
    switch (p) {
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.all:
        return 'All';
    }
  }

  List<FlSpot> _getSpots(List<WeightEntry> sortedEntries) {
    return sortedEntries.map((e) {
      return FlSpot(e.dateTime.millisecondsSinceEpoch.toDouble(), e.weightKg);
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
