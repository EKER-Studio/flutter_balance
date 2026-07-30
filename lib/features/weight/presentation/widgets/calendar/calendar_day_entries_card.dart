import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';

/// Reusable Material 3 card displaying recorded weight entries for a selected date.
class CalendarDayEntriesCard extends StatelessWidget {
  /// The date for which entries are being displayed.
  final DateTime selectedDate;

  /// Recorded weight entries for [selectedDate].
  final List<WeightEntry> entries;

  /// Creates a [CalendarDayEntriesCard] widget.
  const CalendarDayEntriesCard({
    super.key,
    required this.selectedDate,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final timeStr = DateFormat.jm(
                  Localizations.localeOf(context).toString(),
                ).format(entry.dateTime);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.monitor_weight,
                      size: 20,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    '${entry.weightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: Text(
                    entry.note != null && entry.note!.isNotEmpty
                        ? '$timeStr • ${entry.note}'
                        : timeStr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Usuń pomiar',
                    onPressed: () {
                      context.read<WeightBloc>().add(DeleteWeight(entry.id));
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAddWeightSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj kolejny pomiar'),
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
