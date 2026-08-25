import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
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

    final selectedDayHeader = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l10n.entriesFromDate(formattedSelectedDate),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (dayEntries.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.measurementCountPill(dayEntries.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
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
