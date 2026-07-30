import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

/// Reusable Material 3 card displaying recorded weight entries and daily statistics for a selected date.
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
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;
    final isImperial = unit == MeasurementUnit.imperial;
    final unitLabel = isImperial ? 'lb' : 'kg';

    final hasMultipleEntries = entries.length >= 2;

    double averageKg = 0;
    double minKg = 0;
    double maxKg = 0;

    if (hasMultipleEntries) {
      final totalKg = entries.fold<double>(0, (sum, e) => sum + e.weightKg);
      averageKg = totalKg / entries.length;
      minKg = entries
          .map((e) => e.weightKg)
          .reduce((a, b) => a < b ? a : b);
      maxKg = entries
          .map((e) => e.weightKg)
          .reduce((a, b) => a > b ? a : b);
    }

    final displayAverage = isImperial ? kgToLbs(averageKg) : averageKg;
    final displayMin = isImperial ? kgToLbs(minKg) : minKg;
    final displayMax = isImperial ? kgToLbs(maxKg) : maxKg;
    final displayDelta = isImperial ? kgToLbs(maxKg - minKg) : (maxKg - minKg);

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
            if (hasMultipleEntries) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Podsumowanie dnia',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entries.length} pomiary',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Średnia waga',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                            Text(
                              '${displayAverage.toStringAsFixed(1)} $unitLabel',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Zakres (Min / Max)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                            Text(
                              '${displayMin.toStringAsFixed(1)} – ${displayMax.toStringAsFixed(1)} $unitLabel (Δ ${displayDelta.toStringAsFixed(1)})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final displayWeight = isImperial
                    ? kgToLbs(entry.weightKg)
                    : entry.weightKg;
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
                    '${displayWeight.toStringAsFixed(1)} $unitLabel',
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
