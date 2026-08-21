import 'package:flutter/material.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational segmented control pill selector for BMI chart time periods.
class BmiPeriodFilters extends StatelessWidget {
  final TimePeriod period;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const BmiPeriodFilters({
    super.key,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const periods = [TimePeriod.week, TimePeriod.month, TimePeriod.year];

    return PillSegmentedControl<TimePeriod>(
      selectedValue: period,
      onValueChanged: onPeriodChanged,
      expand: false,
      segments: [
        for (final candidate in periods)
          PillSegment(
            value: candidate,
            label: switch (candidate) {
              TimePeriod.week => l10n.week,
              TimePeriod.month => l10n.month,
              TimePeriod.year => l10n.year,
              TimePeriod.all => l10n.all,
            },
          ),
      ],
    );
  }
}
