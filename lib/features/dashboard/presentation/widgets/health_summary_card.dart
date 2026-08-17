/// The Today-screen summary card: latest measurement, BMI badge, and goal progress.


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_dialog.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';

/// An integrated summary card displaying the latest weight, BMI, and goal progress.
///
/// Sections: the latest measurement (converted value, unit label, relative
/// timestamp), a tappable BMI badge that opens the [BmiLegendDialog], and —
/// when a target weight is configured — a goal-progress row that opens the
/// [TargetWeightDialog]. Height, target weight, and unit come from the
/// [AppSettingsBloc]; the measurement itself is passed in.
///
/// The whole card collapses into a single semantics node: the label joins the
/// localized measurement, BMI category, and goal strings with `ExcludeSemantics`
//// hiding the visual children from screen readers.
class HealthSummaryCard extends StatelessWidget {
  /// The latest recorded weight in kilograms.
  final double latestWeightKg;

  /// An optional date of the latest recorded weight measurement.
  final DateTime? lastUpdated;

  /// Creates a [HealthSummaryCard].
  const HealthSummaryCard({
    super.key,
    required this.latestWeightKg,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        final heightCm = state.height;
        final targetWeight = state.targetWeight;
        final weightUnit = state.measurementUnit;
        final l10n = AppLocalizations.of(context);

        final bmi = (heightCm != null && heightCm > 0)
            ? state.calculateBmi(latestWeightKg)
            : double.nan;
        final category = bmi.isFinite ? BmiCategory.fromBmi(bmi) : null;

        final displayWeight = weightUnit == MeasurementUnit.imperial
            ? kgToLbs(latestWeightKg)
            : latestWeightKg;
        final unitLabel = unitLabelFor(weightUnit);

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        final semanticsLabel = [
          '${l10n.lastMeasurementLabel}: ${displayWeight.toStringAsFixed(1)} $unitLabel',
          if (category != null)
            '${category.localizedName(l10n)}, ${l10n.bmiValueShortLabel(bmi.toStringAsFixed(1))}',
          if (targetWeight != null)
            l10n.goalWeightLabel(
              '${(weightUnit == MeasurementUnit.imperial ? kgToLbs(targetWeight) : targetWeight).toStringAsFixed(1)} $unitLabel',
            ),
        ].join('. ');

        return Semantics(
          container: true,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildLatestMeasurementInfo(
                                context,
                                displayWeight,
                                unitLabel,
                                l10n,
                                colorScheme,
                                textTheme,
                              ),
                            ),
                            if (bmi.isFinite)
                              _buildBmiBadge(
                                context,
                                bmi,
                                category,
                                l10n,
                                colorScheme,
                                textTheme,
                              ),
                          ],
                        ),
                        if (targetWeight != null) ...[
                          const SizedBox(height: 16),
                          _buildGoalProgress(
                            context,
                            targetWeight,
                            latestWeightKg,
                            weightUnit,
                            unitLabel,
                            l10n,
                            colorScheme,
                            textTheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the latest-measurement column.
  ///
  /// Includes the label, a large weight value, and a localized relative timestamp.
  Widget _buildLatestMeasurementInfo(
    BuildContext context,
    double displayWeight,
    String unitLabel,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lastMeasurementLabel,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              displayWeight.toStringAsFixed(1),
              style: textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unitLabel,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatTimestamp(context, lastUpdated, l10n),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Builds the tappable BMI badge showing the current value and category color.
  ///
  /// Tapping the badge opens the [BmiLegendDialog].
  Widget _buildBmiBadge(
    BuildContext context,
    double bmi,
    BmiCategory? category,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = category != null
        ? category.chipBackgroundColor()
        : colorScheme.primary.withValues(alpha: 0.1);

    final borderColor = category != null
        ? category.chipContentColor(isDark: isDark).withValues(alpha: 0.3)
        : colorScheme.primary.withValues(alpha: 0.2);

    final contentColor = category != null
        ? category.chipContentColor(isDark: isDark)
        : colorScheme.primary;

    final categoryLabel = category?.localizedName(l10n) ?? '';

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(bmi.toStringAsFixed(1), categoryLabel),
      excludeSemantics: true,
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const BmiLegendDialog(),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category == BmiCategory.normal
                            ? Icons.check_circle
                            : Icons.info,
                        size: 14,
                        color: contentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.localizedName(l10n),
                        style: textTheme.labelMedium?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.bmiValueShortLabel(bmi.toStringAsFixed(1)),
                  style: textTheme.titleMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the goal progress section.
  ///
  /// Shows the goal target, the remaining difference (or a "goal achieved"
  /// message once `currentWeightKg` drops to `targetWeightKg` or below), and a
  /// progress bar. Progress maps the remaining difference onto a fixed 20 kg /
  /// 40 lb reference range: reaching the goal yields 100%, exceeding the range
  /// floors at 0%, and the bar is always drawn at least 5% full. Tapping opens
  /// the [TargetWeightDialog].
  Widget _buildGoalProgress(
    BuildContext context,
    double targetWeightKg,
    double currentWeightKg,
    MeasurementUnit unit,
    String unitLabel,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final displayTarget = unit == MeasurementUnit.imperial
        ? kgToLbs(targetWeightKg)
        : targetWeightKg;

    final differenceKg = currentWeightKg - targetWeightKg;
    final isAchieved = differenceKg <= 0;

    final displayDifference = unit == MeasurementUnit.imperial
        ? kgToLbs(differenceKg.abs())
        : differenceKg.abs();

    final maxDifference = unit == MeasurementUnit.imperial ? 40.0 : 20.0;
    double progress = 1.0;
    if (!isAchieved) {
      progress = 1.0 - (displayDifference / maxDifference).clamp(0.0, 1.0);
    }
    progress = progress.clamp(0.05, 1.0);

    final goalTargetStr = '${displayTarget.toStringAsFixed(1)} $unitLabel';
    final goalDetailStr = isAchieved
        ? l10n.goalAchieved
        : l10n.remainingWeightLabel(
            '${displayDifference.toStringAsFixed(1)} $unitLabel',
          );

    return Semantics(
      button: true,
      label: l10n.goalProgressSemantics(goalTargetStr, goalDetailStr),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _openTargetWeightDialog(context, targetWeightKg, unit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.goalWeightLabel(goalTargetStr),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    goalDetailStr,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //// Opens the [TargetWeightDialog] and dispatches the resulting target weight change to the [AppSettingsBloc].
  Future<void> _openTargetWeightDialog(
    BuildContext context,
    double? targetWeightKg,
    MeasurementUnit unit,
  ) async {
    final displayValue = targetWeightKg != null
        ? (unit == MeasurementUnit.imperial
              ? kgToLbs(targetWeightKg)
              : targetWeightKg)
        : null;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) =>
          TargetWeightDialog(currentValue: displayValue, unit: unit),
    );

    if (result != null && context.mounted) {
      if (result == 'clear') {
        context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
      } else if (result is double) {
        final targetKg = unit == MeasurementUnit.imperial
            ? lbsToKg(result)
            : result;
        context.read<AppSettingsBloc>().add(TargetWeightChanged(targetKg));
      }
    }
  }

  /// Formats the [date] as a localized time or a date-time pair for older measurements.
  ///
  /// Returns an empty string when the [date] is null.
  String _formatTimestamp(
    BuildContext context,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    if (date == null) {
      return '';
    }
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final timeStr = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(date);

    if (isToday) {
      return l10n.todayAtTime(timeStr);
    }
    final dateStr = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    return '$dateStr, $timeStr';
  }
}
