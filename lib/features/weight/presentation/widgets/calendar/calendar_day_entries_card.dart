import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

/// Reusable Material 3 day details card displaying weight entries, notes, and stats.
class CalendarDayEntriesCard extends StatelessWidget {
  /// The selected date.
  final DateTime selectedDate;

  /// List of weight entries recorded on this day.
  final List<WeightEntry> entries;

  /// User's target weight in kg (if set).
  final double? targetWeight;

  /// Creates a [CalendarDayEntriesCard].
  const CalendarDayEntriesCard({
    super.key,
    required this.selectedDate,
    required this.entries,
    this.targetWeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;
    final isImperial = unit == MeasurementUnit.imperial;
    final unitLabel = unitLabelFor(unit);

    final hasMultiple = entries.length >= 2;

    // Check if target weight was reached on this day
    final isGoalAchievedOnDay =
        targetWeight != null && entries.any((e) => e.weightKg <= targetWeight!);

    // Daily Stats
    double averageKg = 0;
    double minKg = 0;
    double maxKg = 0;

    if (hasMultiple) {
      final totalKg = entries.fold<double>(0, (sum, e) => sum + e.weightKg);
      averageKg = totalKg / entries.length;
      minKg = entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
      maxKg = entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    }

    final displayAverage = isImperial ? kgToLbs(averageKg) : averageKg;
    final displayMin = isImperial ? kgToLbs(minKg) : minKg;
    final displayMax = isImperial ? kgToLbs(maxKg) : maxKg;
    final displayDelta = displayMax - displayMin;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Achievement Banner
            if (isGoalAchievedOnDay) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, color: cs.onTertiaryContainer, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.goalAchievedOnDayBanner,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onTertiaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Daily Summary Stats Bar (when 2+ measurements exist)
            if (hasMultiple) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.dailySummaryTitle,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSecondaryContainer,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.multipleEntries(entries.length),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.averageWeight,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: cs.onSecondaryContainer.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                              ),
                              Text(
                                '${displayAverage.toStringAsFixed(1)} $unitLabel',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSecondaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.rangeMinMax,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: cs.onSecondaryContainer.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                              ),
                              Text(
                                '${displayMin.toStringAsFixed(1)} – ${displayMax.toStringAsFixed(1)} $unitLabel (Δ ${displayDelta.toStringAsFixed(1)})',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSecondaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // List of Entries for this day
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final displayWeight = isImperial
                    ? kgToLbs(entry.weightKg)
                    : entry.weightKg;
                final timeStr = DateFormat.jm(
                  Localizations.localeOf(context).toString(),
                ).format(entry.dateTime);

                final meetsGoal =
                    targetWeight != null && entry.weightKg <= targetWeight!;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: meetsGoal
                          ? cs.tertiaryContainer
                          : cs.primaryContainer,
                      child: Icon(
                        meetsGoal ? Icons.star : Icons.monitor_weight_outlined,
                        size: 20,
                        color: meetsGoal
                            ? cs.onTertiaryContainer
                            : cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${displayWeight.toStringAsFixed(1)} $unitLabel',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (meetsGoal) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.goalChipLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: cs.onTertiaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            entry.note != null && entry.note!.isNotEmpty
                                ? '$timeStr • ${entry.note}'
                                : timeStr,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: l10n.deleteMeasurementTooltip,
                      onPressed: () {
                        context.read<WeightBloc>().add(DeleteWeight(entry.id));
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddWeightSheet(initialDate: selectedDate),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addAnotherMeasurement),
            ),
          ],
        ),
      ),
    );
  }
}
