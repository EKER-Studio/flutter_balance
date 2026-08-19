import 'package:flutter/material.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_chart_header.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_line_chart.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_period_filters.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A composite card section displaying BMI history with headers, period tabs, and chart styles.
class BmiChartCard extends StatelessWidget {
  /// The list of recorded weight entries.
  final List<WeightEntry> entries;

  /// The user's recorded height in centimeters.
  final double? heightCm;

  /// The active time period filter.
  final TimePeriod period;

  /// A callback invoked when the user selects a new time period.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [BmiChartCard] widget.
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
    final hasChartData =
        heightCm != null && heightCm! > 0 && entries.length >= 2;

    return Semantics(
      container: true,
      label: l10n.bmi,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BmiChartHeader(
                entries: entries,
                heightCm: heightCm,
                onLegendTap: () => _showLegendDialog(context),
              ),
              if (hasChartData) ...[
                const SizedBox(height: 12),
                BmiPeriodFilters(
                  period: period,
                  onPeriodChanged: onPeriodChanged,
                ),
              ],
              const SizedBox(height: 16),
              _buildChartBody(context, cs, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartBody(
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

    return BmiLineChart(
      entries: entries,
      heightCm: heightCm!,
      period: period,
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const BmiLegendDialog(),
    );
  }
}
