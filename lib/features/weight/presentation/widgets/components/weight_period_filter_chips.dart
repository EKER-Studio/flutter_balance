import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational wrap of choice chips for selecting the chart time period.
class WeightPeriodFilterChips extends StatelessWidget {
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const WeightPeriodFilterChips({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: TimePeriod.values.map((p) {
        final label = _getPeriodName(p, l10n);
        final isSelected = period == p;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: '$label ${l10n.chartSemanticsFilter}',
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPeriodChanged(p);
                }
              },
            ),
          ),
        );
      }).toList(),
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
}
