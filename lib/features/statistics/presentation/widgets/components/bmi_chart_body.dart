import 'package:flutter/material.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_line_chart.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget resolving the BMI chart canvas, empty placeholder, or missing height guide.
class BmiChartBody extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? heightCm;
  final TimePeriod period;

  const BmiChartBody({
    super.key,
    required this.entries,
    required this.heightCm,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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

    return BmiLineChart(entries: entries, heightCm: heightCm!, period: period);
  }
}
