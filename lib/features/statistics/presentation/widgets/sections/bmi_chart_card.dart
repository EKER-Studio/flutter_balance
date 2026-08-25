import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_chart_body.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_chart_header.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_period_filters.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A composite card section displaying BMI history with headers, period tabs, and chart styles.
class BmiChartCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? heightCm;
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

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
          padding: const EdgeInsets.all(20),
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
              BmiChartBody(
                entries: entries,
                heightCm: heightCm,
                period: period,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegendDialog(BuildContext context) {
    AppAnalytics.logStatisticsBmiLegendTapped();
    AppAnalytics.logDialogBmiLegendOpened();
    final latestWeightKg = entries.isNotEmpty
        ? (entries.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime)))
              .first
              .weightKg
        : null;
    showDialog<void>(
      context: context,
      builder: (_) =>
          BmiLegendDialog(latestWeightKg: latestWeightKg, heightCm: heightCm),
    );
  }
}
