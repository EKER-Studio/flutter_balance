// lib/features/weight/presentation/widgets/bmi_chart_card.dart

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A composite card displaying BMI history with unified headers, period tabs, and chart styles.
class BmiChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? heightCm;
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [BmiChartCard].
  const BmiChartCard({
    super.key,
    required this.entries,
    required this.heightCm,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Unified Header Row (Title + Category Badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 20,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.bmi,
                      style: textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _BmiHeaderBadge(entries: entries, heightCm: heightCm),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Centered Period Selector Tabs
            _BmiPeriodFilters(period: period, onPeriodChanged: onPeriodChanged),
            const SizedBox(height: 16),

            // 3. Line Chart
            SizedBox(height: 190, child: _buildChartContent(context, cs, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (heightCm == null || heightCm! <= 0) {
      return Center(
        child: Text(
          l10n.bmiChartNoHeight,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          l10n.chartEmpty,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final hMeters = heightCm! / 100.0;
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

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(0, sortedEntries.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.surfaceContainerHighest,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
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
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
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
              show: period == TimePeriod.week,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: cs.primary,
                    strokeWidth: 2,
                    strokeColor: cs.surface,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.2),
                  cs.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
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

/// Category badge / Help button pinned to the top-right
class _BmiHeaderBadge extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? heightCm;

  const _BmiHeaderBadge({required this.entries, required this.heightCm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (heightCm == null || heightCm! <= 0 || entries.isEmpty) {
      return IconButton(
        icon: Icon(
          Icons.help_outline_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        onPressed: () => _showLegend(context),
      );
    }

    final sorted = [...entries]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final hMeters = heightCm! / 100.0;
    final bmi = sorted.first.weightKg / (hMeters * hMeters);
    final category = BmiCategory.fromBmi(bmi);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showLegend(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: category.chipBackgroundColor(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: category.chipContentColor(isDark: isDark),
            ),
            const SizedBox(width: 4),
            Text(
              category.localizedName(l10n),
              style: TextStyle(
                color: category.chipContentColor(isDark: isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const BmiLegendDialog());
  }
}

/// Centered period selector tabs
class _BmiPeriodFilters extends StatelessWidget {
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const _BmiPeriodFilters({
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
          final isSelected = period == candidate;
          final label = switch (candidate) {
            TimePeriod.week => l10n.week,
            TimePeriod.month => l10n.month,
            TimePeriod.year => l10n.year,
            TimePeriod.all => l10n.all,
          };

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: TextButton(
              onPressed: () => onPeriodChanged(candidate),
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFFA8C7FA) : null,
                foregroundColor: isSelected
                    ? const Color(0xFF00325B)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
