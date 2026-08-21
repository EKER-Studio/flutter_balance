import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/chart_period_filters.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/weight_delta_chip.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/weight_line_chart.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying the weight trend line chart, period filter, and delta chip.
class WeightTrendChartCard extends StatelessWidget {
  /// The entries to plot, pre-filtered by [period].
  final List<WeightEntry> entries;

  /// The currently selected chart time period.
  final TimePeriod period;

  /// The measurement unit used to format the plotted values.
  final MeasurementUnit measurementUnit;

  /// A callback invoked when a new chart period is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  const WeightTrendChartCard({
    super.key,
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

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.weightTrend,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                WeightDeltaChip(
                  entries: entries,
                  measurementUnit: measurementUnit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ChartPeriodFilters(
              period: period,
              onPeriodChanged: onPeriodChanged,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        l10n.chartEmpty,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : WeightLineChart(
                      entries: entries,
                      period: period,
                      measurementUnit: measurementUnit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
