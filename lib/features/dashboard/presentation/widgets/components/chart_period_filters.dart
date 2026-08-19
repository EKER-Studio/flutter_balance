import 'package:flutter/material.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A centered row of segmented pill buttons for selecting the chart time period.
class ChartPeriodFilters extends StatelessWidget {
  /// The currently selected time period.
  final TimePeriod period;

  /// A callback invoked when a new period is selected.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// Creates a [ChartPeriodFilters] widget.
  const ChartPeriodFilters({
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
        for (final p in periods)
          PillSegment(value: p, label: _periodLabel(p, l10n)),
      ],
    );
  }

  String _periodLabel(TimePeriod period, AppLocalizations l10n) {
    return switch (period) {
      TimePeriod.week => l10n.week,
      TimePeriod.month => l10n.month,
      TimePeriod.year => l10n.year,
      TimePeriod.all => l10n.all,
    };
  }
}
