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
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isGoalAchievedOnDay) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.military_tech_outlined,
                    color: isDark
                        ? Colors.green.shade300
                        : Colors.green.shade800,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.goalAchievedOnDayBanner,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.green.shade300
                          : Colors.green.shade800,
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
            final categoryColor =
                category?.chipContentColor(isDark: isDark) ?? cs.primary;

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
                  side: BorderSide(
                    color: index == 0
                        ? cs.primary.withValues(alpha: 0.8)
                        : cs.outlineVariant.withValues(alpha: 0.2),
                    width: index == 0 ? 1.5 : 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: meetsGoal
                                                ? const Color(0xFF4CAF50)
                                                : cs.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          timeStr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (entry.note != null &&
                                            entry.note!.trim().isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.description_outlined,
                                            size: 14,
                                            color: cs.primary,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${displayWeight.toStringAsFixed(1)} $unitLabel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                            fontSize: 32,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (bmi.isFinite)
                                      Text(
                                        l10n.bmiValueLabel(
                                          bmi.toStringAsFixed(1),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                              fontSize: 15,
                                            ),
                                      ),
                                    if (categoryText.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: categoryColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: categoryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              categoryText,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: categoryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (entry.note != null &&
                              entry.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.35,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 13,
                                        color: cs.onSurfaceVariant.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        l10n.note.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.8),
                                              letterSpacing: 0.5,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.note!.trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 4,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          Icons.more_vert,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        tooltip: l10n.moreOptions,
                        onSelected: (value) {
                          if (value == 'edit') {
                            AppAnalytics.logCalendarEntryClicked(
                              entryId: entry.id,
                              hasNote: entry.note != null,
                            );
                            AppAnalytics.logDialogEditWeightOpened(entry.id);
                            final weightBloc = context.read<WeightBloc>();
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (sheetCtx) => BlocProvider.value(
                                value: weightBloc,
                                child: AddWeightSheet(existingEntry: entry),
                              ),
                            );
                          } else if (value == 'delete') {
                            _confirmDelete(context, entry.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: cs.onSurface,
                                ),
                                const SizedBox(width: 12),
                                Text(l10n.edit),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.delete,
                                  style: TextStyle(color: Colors.red.shade400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
