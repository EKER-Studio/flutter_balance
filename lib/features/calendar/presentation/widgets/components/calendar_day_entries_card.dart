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
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/bmi_badge.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
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

    bool isEntryGoalAchieved(WeightEntry e) {
      if (targetWeight != null) {
        switch (appSettingsState.weightGoalMode) {
          case WeightGoalMode.lose:
            return e.weightKg <= targetWeight!;
          case WeightGoalMode.gain:
            return e.weightKg >= targetWeight!;
          case WeightGoalMode.maintain:
            return (e.weightKg - targetWeight!).abs() <= 1.0;
        }
      }
      return false;
    }

    /// Whether at least one entry on this day reaches the target weight.
    final isGoalAchievedOnDay =
        targetWeight != null && entries.any(isEntryGoalAchieved);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isGoalAchievedOnDay) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.green.shade300 : Colors.green.shade700)
                    .withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: isDark
                        ? Colors.green.shade300
                        : Colors.green.shade700,
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
                          : Colors.green.shade700,
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

            final meetsGoal = isEntryGoalAchieved(entry);

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
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                            ? (isDark
                                                  ? Colors.green.shade300
                                                  : Colors.green.shade700)
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
                                            fontSize: 13,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      displayWeight.toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: cs.primary,
                                            fontSize: 32,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      unitLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (bmi.isFinite)
                                BmiBadge(
                                  bmi: bmi,
                                  category: category,
                                  onTap: () => _openBmiLegendDialog(
                                    context,
                                    bmi: bmi,
                                    category: category?.name ?? 'unknown',
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: cs.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  tooltip: l10n.moreOptions,
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      AppAnalytics.logCalendarEntryClicked(
                                        entryId: entry.id,
                                        hasNote: entry.note != null,
                                      );
                                      final weightBloc = context
                                          .read<WeightBloc>();
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (ctx) => BlocProvider.value(
                                          value: weightBloc,
                                          child: AddWeightSheet(
                                            existingEntry: entry,
                                          ),
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
                                            color: cs.error,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.delete,
                                            style: TextStyle(color: cs.error),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (entry.note != null &&
                          entry.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsetsDirectional.only(start: 10),
                          decoration: BoxDecoration(
                            border: BorderDirectional(
                              start: BorderSide(width: 2.5, color: cs.outline),
                            ),
                          ),
                          child: Text(
                            entry.note!.trim(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            AppAnalytics.logCalendarAddMeasurementClicked();
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

  void _openBmiLegendDialog(
    BuildContext context, {
    required double bmi,
    required String category,
  }) {
    AppAnalytics.logTodayBmiBadgeTapped(category: category);
    AppAnalytics.logDialogBmiLegendOpened();
    showDialog<void>(
      context: context,
      builder: (context) =>
          BmiLegendDialog(currentCategory: BmiCategory.fromBmi(bmi)),
    );
  }
}
