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
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';

/// A card displaying weight entries, notes, and stats for a selected day.
class CalendarDayEntriesCard extends StatelessWidget {
  /// The selected date.
  final DateTime selectedDate;

  /// The list of [WeightEntry] records for this day.
  final List<WeightEntry> entries;

  /// The user's target weight in kilograms, if set.
  final double? targetWeight;

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
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.stars,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.green.shade800
                        : Colors.green.shade300,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.goalAchievedOnDayBanner,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.green.shade800
                          : Colors.green.shade300,
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

            return MergeSemantics(
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    // Reserved: tap-to-edit entry handling.
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: meetsGoal
                              ? Colors.green.withValues(alpha: 0.15)
                              : cs.secondaryContainer,
                          child: Icon(
                            meetsGoal ? Icons.star : Icons.monitor_weight,
                            size: 24,
                            color: meetsGoal
                                ? (Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.green.shade800
                                      : Colors.green.shade300)
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
                                  Expanded(
                                    child: Text(
                                      entry.note != null &&
                                              entry.note!.isNotEmpty
                                          ? '$timeStr • ${entry.note}'
                                          : timeStr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                              bmi.isFinite
                                  ? l10n.bmiValueLabel(bmi.toStringAsFixed(1))
                                  : '',
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
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
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
          label: Text(l10n.addAnotherMeasurement),
        ),
      ],
    );
  }

  /// Prompts the user for confirmation before deleting the entry with [entryId].
  Future<void> _confirmDelete(BuildContext context, int entryId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          size: 28,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
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
