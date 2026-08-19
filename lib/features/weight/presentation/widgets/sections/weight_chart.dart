import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/presentation/widgets/components/weight_chart_canvas.dart';
import 'package:balance/features/weight/presentation/widgets/components/weight_period_filter_chips.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A chart section that displays weight history over time.
///
/// Plots [entries] on a time-based X-axis, converts values into the active
/// measurement unit, and renders the optional [targetWeight] as a dashed
/// reference line.
class WeightChart extends StatelessWidget {
  /// The list of weight entries to plot.
  final List<WeightEntry> entries;

  /// The currently selected time period for formatting the X-axis.
  final TimePeriod period;

  /// A callback fired when the user selects a new time period.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// An optional target weight to display as a horizontal reference line.
  final double? targetWeight;

  /// An optional fixed height for the chart canvas. Defaults to 280px.
  final double chartHeight;

  /// Creates a [WeightChart] widget.
  const WeightChart({
    super.key,
    required this.entries,
    required this.period,
    required this.onPeriodChanged,
    this.chartHeight = 280,
    this.targetWeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entries.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: Center(child: Text(l10n.chartEmpty)),
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeightPeriodFilterChips(
          period: period,
          onPeriodChanged: onPeriodChanged,
        ),
        const SizedBox(height: 16),
        WeightChartCanvas(
          sortedEntries: sortedEntries,
          period: period,
          unit: unit,
          targetWeight: targetWeight,
          chartHeight: chartHeight,
        ),
      ],
    );
  }
}
