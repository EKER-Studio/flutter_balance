/// Empty state shown when the selected calendar day has no measurements.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Empty state for a selected day without measurements, offering a shortcut
//// to add the first entry for that date via [AddWeightSheet].
class CalendarDayEmptyCard extends StatelessWidget {
  /// The selected date with zero measurements.
  final DateTime selectedDate;

  const CalendarDayEmptyCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: cs.secondaryContainer,
                child: Icon(
                  Icons.event_busy,
                  size: 40,
                  color: cs.onSecondaryContainer,
                ),
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
                  showDialog<void>(
                    context: context,
                    builder: (dialogCtx) => BlocProvider.value(
                      value: context.read<WeightBloc>(),
                      child: AddWeightSheet(initialDate: selectedDate),
                    ),
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
