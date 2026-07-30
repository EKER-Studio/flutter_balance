import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Reusable Material 3 empty state card for dates without weight measurements.
class CalendarDayEmptyCard extends StatelessWidget {
  /// The date currently selected in the calendar.
  final DateTime selectedDate;

  /// Creates a [CalendarDayEmptyCard] widget for the given [selectedDate].
  const CalendarDayEmptyCard({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.event_busy,
                size: 40,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noEntriesToday == 'No weight measurements recorded today.'
                  ? 'Brak pomiarów w tym dniu'
                  : l10n.noEntriesToday,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nie dodano jeszcze żadnych danych dla wybranej daty. Regularne pomiary pomagają lepiej śledzić postępy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showAddWeightSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj pomiar'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(selectedDate, now);
    final initialDateTime = isToday
        ? now
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            12,
            0,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddWeightSheet(initialDate: initialDateTime),
    );
  }
}
