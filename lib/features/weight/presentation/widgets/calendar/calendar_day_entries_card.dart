import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_state.dart';
import 'package:balance/presentation/bloc/settings/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';

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
    final appSettingsState = context.watch<AppSettingsBloc>().state;
    final unit = appSettingsState.measurementUnit;
    final heightCm = appSettingsState.height;
    final isImperial = unit == MeasurementUnit.imperial;
    final unitLabel = unitLabelFor(unit);

    // Check if target weight was reached on this day
    final isGoalAchievedOnDay =
        targetWeight != null && entries.any((e) => e.weightKg <= targetWeight!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Goal Achievement Banner
        if (isGoalAchievedOnDay) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // List of Entries for this day
        ListView.separated(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final displayWeight = isImperial
                ? kgToLbs(entry.weightKg)
                : entry.weightKg;
            final timeStr = DateFormat.Hm(
              Localizations.localeOf(context).toString(),
            ).format(entry.dateTime);

            final meetsGoal =
                targetWeight != null && entry.weightKg <= targetWeight!;

            final bmi = (heightCm != null && heightCm > 0)
                ? appSettingsState.calculateBmi(entry.weightKg)
                : double.nan;
            final category = bmi.isFinite ? BmiCategory.fromBmi(bmi) : null;
            final categoryText = category?.localizedName(l10n) ?? '';

            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  // Optional: handle tap (edit?)
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: meetsGoal
                            ? cs.tertiaryContainer
                            : cs.secondaryContainer,
                        child: Icon(
                          meetsGoal ? Icons.star : Icons.monitor_weight,
                          size: 24,
                          color: meetsGoal
                              ? cs.onTertiaryContainer
                              : cs.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${displayWeight.toStringAsFixed(1)} $unitLabel',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.note != null && entry.note!.isNotEmpty
                                      ? '$timeStr • ${entry.note}'
                                      : timeStr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bmi.isFinite ? 'BMI ${bmi.toStringAsFixed(1)}' : '',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                          ),
                          if (categoryText.isNotEmpty)
                            Text(
                              categoryText,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: l10n.deleteMeasurementTooltip,
                        color: cs.onSurfaceVariant,
                        onPressed: () => _confirmDelete(context, entry.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
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
    );
  }

  /// Prompts for confirmation before deleting [entryId].
  Future<void> _confirmDelete(BuildContext context, int entryId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteEntryTooltip),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      context.read<WeightBloc>().add(DeleteWeight(entryId));
    }
  }
}
