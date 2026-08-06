import 'package:flutter/material.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Reusable Material 3 empty state card for a selected calendar day without measurements.
class CalendarDayEmptyCard extends StatelessWidget {
  /// The selected date with zero measurements.
  final DateTime selectedDate;

  /// Creates [CalendarDayEmptyCard].
  const CalendarDayEmptyCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: cs.secondaryContainer,
              child: Icon(
                Icons.event_busy,
                size: 40,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noEntriesForDate,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noEntriesForDateSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddWeightSheet(initialDate: selectedDate),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addWeight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
