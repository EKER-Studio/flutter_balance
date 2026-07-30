import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Bottom sheet displaying entries for a specific day with management actions.
class CalendarDayDetailSheet extends StatelessWidget {
  /// The target date for displaying and recording entries.
  final DateTime date;

  /// Recorded weight entries for [date].
  final List<WeightEntry> entries;

  /// Creates a [CalendarDayDetailSheet] widget.
  const CalendarDayDetailSheet({
    super.key,
    required this.date,
    required this.entries,
  });

  /// Displays the [CalendarDayDetailSheet] modally.
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<WeightEntry> entries,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => CalendarDayDetailSheet(
        date: date,
        entries: entries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noEntriesToday,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  final timeStr = DateFormat.jm(
                    Localizations.localeOf(context).toString(),
                  ).format(e.dateTime);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.monitor_weight,
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                    subtitle: Text(
                      e.note != null && e.note!.isNotEmpty
                          ? '$timeStr • ${e.note}'
                          : timeStr,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        context.read<WeightBloc>().add(DeleteWeight(e.id));
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddWeightSheetForDate(context, date);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addMeasurementForDate(dateStr)),
          ),
        ],
      ),
    );
  }

  void _showAddWeightSheetForDate(BuildContext context, DateTime targetDate) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(targetDate, now);
    final initialDateTime = isToday
        ? now
        : DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            12,
            0,
          );

    showDialog(
      context: context,
      builder: (_) => AddWeightSheet(initialDate: initialDateTime),
    );
  }
}
