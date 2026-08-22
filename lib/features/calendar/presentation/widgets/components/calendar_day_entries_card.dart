// The selected day's weight entries with per-entry stats and actions.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';

/// Lists the weight entries for the selected day with per-entry BMI stats, a
/// goal-achieved banner, delete affordances, and an add-measurement action.
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

    /// Whether at least one entry on this day reaches the target weight.
    final isGoalAchievedOnDay =
        targetWeight != null && entries.any((e) => e.weightKg <= targetWeight!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

            return Semantics(
              container: true,
              label:
                  '${DateFormat.jm(Localizations.localeOf(context).toString()).format(entry.dateTime)}, ${displayWeight.toStringAsFixed(1)} $unitLabel${entry.note != null ? ", ${entry.note}" : ""}${categoryText.isNotEmpty ? ", $categoryText" : ""}',
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    AppAnalytics.logCalendarEntryClicked(
                      entryId: entry.id,
                      hasNote: entry.note != null,
                    );
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
        FilledButton.icon(
          onPressed: () {
            final dateStr = selectedDate.toIso8601String().substring(0, 10);
            AppAnalytics.logCalendarAddMeasurementClicked(dateStr);
            AppAnalytics.logDialogAddWeightOpened('calendar');
            final weightBloc = context.read<WeightBloc>();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetCtx) => BlocProvider.value(
                value: weightBloc,
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
    AppAnalytics.logDialogDeleteWeightOpened(entryId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(l10n.deleteEntryTitle),
        content: SizedBox(width: 320, child: Text(l10n.deleteEntryMessage)),
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
      AppAnalytics.logCalendarEntryDeleted(entryId);
      if (!context.mounted) return;
      context.read<WeightBloc>().add(DeleteWeight(entryId));
    } else {
      AppAnalytics.logDialogDeleteWeightCancelled();
    }
  }
}
