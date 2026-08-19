import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/statistics/presentation/widgets/components/weight_detail_row.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying the highest, lowest, and average weight across all recorded entries.
class WeightRangeCard extends StatelessWidget {
  /// The list of weight entries to calculate extremes and averages from.
  final List<WeightEntry> entries;

  /// The active measurement unit.
  final MeasurementUnit unit;

  /// Creates a [WeightRangeCard] widget.
  const WeightRangeCard({
    super.key,
    required this.entries,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final unitLabel = unitLabelFor(unit);

    final maxEntry = entries.reduce((a, b) => a.weightKg > b.weightKg ? a : b);
    final maxDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(maxEntry.weightKg)
        : maxEntry.weightKg;
    final maxDateText = _formatEntryDate(context, maxEntry.dateTime, l10n);

    final minEntry = entries.reduce((a, b) => a.weightKg < b.weightKg ? a : b);
    final minDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(minEntry.weightKg)
        : minEntry.weightKg;
    final minDateText = _formatEntryDate(context, minEntry.dateTime, l10n);

    final weights = entries.map((e) => e.weightKg).toList();
    final avgWeightKg = weights.reduce((a, b) => a + b) / weights.length;
    final avgDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(avgWeightKg)
        : avgWeightKg;

    return Semantics(
      container: true,
      label:
          '${l10n.weightRangeSemanticsPrefix}${l10n.highest} ${maxDisplay.toStringAsFixed(1)} $unitLabel, ${l10n.lowest} ${minDisplay.toStringAsFixed(1)} $unitLabel, ${l10n.averageWeight} ${avgDisplay.toStringAsFixed(1)} $unitLabel',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 24, color: cs.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.weightRangeCardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              WeightDetailRow(
                icon: Icons.north_east,
                iconColor: cs.error,
                label: l10n.highest,
                value: '${maxDisplay.toStringAsFixed(1)} $unitLabel',
                date: maxDateText,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, thickness: 0.5),
              ),
              WeightDetailRow(
                icon: Icons.south_east,
                iconColor: cs.primary,
                label: l10n.lowest,
                value: '${minDisplay.toStringAsFixed(1)} $unitLabel',
                date: minDateText,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, thickness: 0.5),
              ),
              WeightDetailRow(
                icon: Icons.bar_chart,
                iconColor: cs.secondary,
                label: l10n.averageWeight,
                value: '${avgDisplay.toStringAsFixed(1)} $unitLabel',
                date: l10n.allEntriesLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatEntryDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return l10n.today;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}
