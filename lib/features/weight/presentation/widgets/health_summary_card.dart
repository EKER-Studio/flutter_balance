import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:pure_weight/presentation/widgets/target_weight_dialog.dart';
import 'package:pure_weight/features/weight/presentation/widgets/bmi_legend_dialog.dart';

/// An integrated summary card displaying latest weight, BMI, and goal progress.
class HealthSummaryCard extends StatelessWidget {
  /// The latest recorded weight in kilograms.
  final double latestWeightKg;

  /// Optional date of the latest recorded weight measurement.
  final DateTime? lastUpdated;

  /// Creates a [HealthSummaryCard] with [latestWeightKg] and optional [lastUpdated].
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
                    padding: const EdgeInsets.all(24),
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

  /// Builds the latest-measurement column: label, big weight value, and a
  /// localized relative timestamp.
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

  /// Builds the tappable BMI badge showing the current value and category
  /// color; tapping opens the [BmiLegendDialog].
  Widget _buildBmiBadge(
    BuildContext context,
    double bmi,
    BmiCategory? category,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    MaterialColor? baseColor;
    if (category != null) {
      switch (category) {
        case BmiCategory.underweight:
          baseColor = Colors.blue;
          break;
        case BmiCategory.normal:
          baseColor = Colors.green;
          break;
        case BmiCategory.overweight:
          baseColor = Colors.orange;
          break;
        case BmiCategory.obese:
          baseColor = Colors.red;
          break;
      }
    }

    final bgColor = baseColor != null
        ? baseColor.withValues(alpha: 0.15)
        : colorScheme.primary.withValues(alpha: 0.1);

    final borderColor = baseColor != null
        ? (isDark ? baseColor.shade300 : baseColor.shade800).withValues(
            alpha: 0.3,
          )
        : colorScheme.primary.withValues(alpha: 0.2);

    final contentColor = baseColor != null
        ? (isDark ? baseColor.shade300 : baseColor.shade800)
        : colorScheme.primary;

    return Ink(
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
    );
  }

  /// Builds the goal progress section: remaining weight text and a progress
  /// bar; tapping opens the target weight dialog.
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

    // Calculate progress percentage based on some arbitrary reasonable range,
    // or just 100% if achieved. For a simple visual, let's assume a 10kg/20lbs range
    // from target is 0%, target is 100%.
    // Or just a fixed 75% for now if not achieved, since we don't store initial weight easily here.
    // A better approach is to use a fixed max difference to calculate progress.
    final maxDifference = unit == MeasurementUnit.imperial ? 40.0 : 20.0;
    double progress = 1.0;
    if (!isAchieved) {
      progress = 1.0 - (displayDifference / maxDifference).clamp(0.0, 1.0);
    }
    // Clamp to minimum 5% to always show a bit of the bar
    progress = progress.clamp(0.05, 1.0);

    return InkWell(
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
                  l10n.goalWeightLabel(
                    '${displayTarget.toStringAsFixed(1)} $unitLabel',
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isAchieved
                      ? l10n.goalAchieved
                      : l10n.remainingWeightLabel(
                          '${displayDifference.toStringAsFixed(1)} $unitLabel',
                        ),
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
    );
  }

  /// Opens the [TargetWeightDialog] and dispatches the resulting target
  /// weight change (or its removal) to [AppSettingsBloc].
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

  /// Formats [date] as a localized time ("today at 7:30 AM") or a date-time
  /// pair for older measurements, returning an empty string when [date] is null.
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
