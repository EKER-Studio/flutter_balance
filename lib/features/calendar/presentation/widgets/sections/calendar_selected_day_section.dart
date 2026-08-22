import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_empty_card.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_entries_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A section displaying the selected day's header summary and its weight entry list or empty placeholder.
class CalendarSelectedDaySection extends StatelessWidget {
  /// The selected day.
  final DateTime selectedDate;

  /// The list of weight entries recorded on [selectedDate].
  final List<WeightEntry> dayEntries;

  /// An optional target goal weight in kilograms.
  final double? targetWeight;

  /// The active measurement unit.
  final MeasurementUnit unit;

  const CalendarSelectedDaySection({
    super.key,
    required this.selectedDate,
    required this.dayEntries,
    required this.targetWeight,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final formattedSelectedDate = DateFormat.MMMMd(locale).format(selectedDate);
    final isImperial = unit == MeasurementUnit.imperial;
    final unitLabel = unitLabelFor(unit);

    double averageKg = 0;
    if (dayEntries.isNotEmpty) {
      averageKg =
          dayEntries.fold<double>(0, (sum, e) => sum + e.weightKg) /
          dayEntries.length;
    }
    final displayAverage = isImperial ? kgToLbs(averageKg) : averageKg;

    final selectedDayHeader = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.entriesFromDate(formattedSelectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (dayEntries.length > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.multipleEntries(dayEntries.length)} • ${l10n.averageWeight}: ${displayAverage.toStringAsFixed(1)} $unitLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        selectedDayHeader,
        if (dayEntries.isEmpty)
          CalendarDayEmptyCard(selectedDate: selectedDate)
        else
          CalendarDayEntriesCard(
            selectedDate: selectedDate,
            entries: dayEntries,
            targetWeight: targetWeight,
          ),
      ],
    );
  }
}
