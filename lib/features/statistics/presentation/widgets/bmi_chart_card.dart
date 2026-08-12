import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A composite card that displays a BMI chart over time with colored zones and a summary header.
class BmiChartCard extends StatelessWidget {
  /// All recorded weight entries used to compute and plot the BMI history.
  final List<WeightEntry> entries;

  /// The user's height in centimetres, required to derive BMI values.
  ///
  /// When null, zero, or when there are too few entries, the card shows a
  /// contextual empty-state message instead of a chart.
  final double? heightCm;

  /// Creates a [BmiChartCard] with the given [entries] and [heightCm].
  const BmiChartCard({
    super.key,
    required this.entries,
    required this.heightCm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label: l10n.bmi,
      child: Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, cs, l10n),
              const SizedBox(height: 24),
              _buildChartContent(context, cs, l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the card header: a title row with a tappable BMI category chip
  /// when height and entries are available, otherwise a legend help button.
  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (heightCm == null || heightCm! <= 0 || entries.isEmpty) {
      return Row(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 22, color: cs.secondary),
          const SizedBox(width: 8),
          Text(
            l10n.bmi,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () => _showLegendDialog(context),
            tooltip: l10n.bmiLegendTitle,
          ),
        ],
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final latestWeightKg = sortedEntries.first.weightKg;
    final hMeters = heightCm! / 100.0;
    final hSquared = hMeters * hMeters;
    final currentBmi = latestWeightKg / hSquared;

    final category = BmiCategory.fromBmi(currentBmi);
    final categoryLabel = category.localizedName(l10n);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = category.chipBackgroundColor();
    final categoryTextColor = category.chipContentColor(isDark: isDark);

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(
        currentBmi.toStringAsFixed(1),
        categoryLabel,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _showLegendDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(
                Icons.monitor_weight_outlined,
                size: 22,
                color: cs.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.bmi,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: categoryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the [BmiLegendDialog] explaining BMI category colors.
  void _showLegendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const BmiLegendDialog(),
    );
  }

  /// Builds the chart area: the BMI LineChart when height and at least two
  /// entries are available, otherwise a contextual empty-state message.
  Widget _buildChartContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    if (heightCm == null || heightCm! <= 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.bmiChartNoHeight,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    if (entries.isEmpty || entries.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.chartEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    // Prepare data
    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final hMeters = heightCm! / 100.0;
    final hSquared = hMeters * hMeters;

    final spots = <FlSpot>[];
    final firstDate = sortedEntries.first.dateTime;
    double minBmi = double.infinity;
    double maxBmi = double.negativeInfinity;

    for (final entry in sortedEntries) {
      final bmi = entry.weightKg / hSquared;
      if (bmi < minBmi) minBmi = bmi;
      if (bmi > maxBmi) maxBmi = bmi;

      final days = entry.dateTime.difference(firstDate).inDays.toDouble();
      spots.add(FlSpot(days, bmi));
    }

    // Padding for Y axis
    final range = maxBmi - minBmi;
    final padding = (range * 0.1).clamp(1.0, double.infinity);

    final minY = (minBmi - padding).floorToDouble().clamp(10.0, 100.0);
    final maxY = (maxBmi + padding).ceilToDouble();

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: cs.surfaceContainerHighest,
                  strokeWidth: 1,
                  dashArray: [5, 5],
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
                  reservedSize: 35,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: cs.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: cs.primary,
                      strokeWidth: 2,
                      strokeColor: cs.surface,
                    );
                  },
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
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.secondaryContainer,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final textStyle = TextStyle(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    );
                    final formattedValue = touchedSpot.y.toStringAsFixed(1);
                    return LineTooltipItem(formattedValue, textStyle);
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Computes the X-axis label interval for [sortedEntries] so roughly four
  /// labels fit across the visible time span.
  double _getBottomInterval(List<WeightEntry> sortedEntries) {
    if (sortedEntries.length <= 1) return 1;

    final days = sortedEntries.last.dateTime
        .difference(sortedEntries.first.dateTime)
        .inDays;

    if (days <= 0) return 1;
    return (days / 4).clamp(1.0, double.infinity);
  }

  /// Formats the date shown under each bottom axis tick, switching to a
  /// month-year format when the chart spans more than 180 days.
  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<WeightEntry> sortedEntries,
    BuildContext context,
  ) {
    if (sortedEntries.isEmpty) return const SizedBox.shrink();

    final firstDate = sortedEntries.first.dateTime;
    final lastDate = sortedEntries.last.dateTime;
    final maxDays = lastDate.difference(firstDate).inDays.toDouble();

    if (value < 0 || value > maxDays) {
      return const SizedBox.shrink();
    }

    final date = firstDate.add(Duration(days: value.round()));
    // Use the locale dynamically
    final locale = Localizations.localeOf(context).toString();

    final formattedDate = maxDays > 180
        ? DateFormat.yMMM(locale).format(date)
        : DateFormat.MMMd(locale).format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        formattedDate,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}
