import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying progress toward a user-defined target weight,
/// or an interactive prompt to set one when not configured yet.
class GoalProgressBar extends StatelessWidget {
  /// The target weight in kilograms, or `null` if not set yet.
  final double? targetWeightKg;

  /// The current recorded weight in kilograms.
  final double currentWeightKg;

  /// The active measurement unit.
  final MeasurementUnit unit;

  /// The measurement unit label (e.g. 'kg' or 'lb').
  final String unitLabel;

  /// The active weight goal mode (lose, maintain, or gain).
  final WeightGoalMode goalMode;

  /// An optional callback invoked when the progress bar is tapped.
  final VoidCallback? onTap;

  const GoalProgressBar({
    super.key,
    required this.targetWeightKg,
    required this.currentWeightKg,
    required this.unit,
    required this.unitLabel,
    this.goalMode = WeightGoalMode.lose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final target = targetWeightKg;
    final hasTarget = target != null;

    final String goalTargetStr;
    final String goalDetailStr;
    final double progress;
    final bool isAchieved;
    final String semanticsLabel;

    if (hasTarget) {
      final displayTarget = unit == MeasurementUnit.imperial
          ? kgToLbs(target)
          : target;

      final double displayDifference;

      switch (goalMode) {
        case WeightGoalMode.lose:
          final differenceKg = currentWeightKg - target;
          isAchieved = differenceKg <= 0;
          displayDifference = unit == MeasurementUnit.imperial
              ? kgToLbs(differenceKg.abs())
              : differenceKg.abs();
          final maxDifference = unit == MeasurementUnit.imperial ? 40.0 : 20.0;
          double calcProgress = 1.0;
          if (!isAchieved) {
            calcProgress =
                1.0 - (displayDifference / maxDifference).clamp(0.0, 1.0);
          }
          progress = calcProgress.clamp(0.05, 1.0);
          goalDetailStr = isAchieved
              ? l10n.goalAchieved
              : l10n.remainingWeightLabel(
                  '${displayDifference.toStringAsFixed(1)} $unitLabel',
                );

        case WeightGoalMode.gain:
          final differenceKg = target - currentWeightKg;
          isAchieved = differenceKg <= 0;
          displayDifference = unit == MeasurementUnit.imperial
              ? kgToLbs(differenceKg.abs())
              : differenceKg.abs();
          final maxDifference = unit == MeasurementUnit.imperial ? 40.0 : 20.0;
          double calcProgress = 1.0;
          if (!isAchieved) {
            calcProgress =
                1.0 - (displayDifference / maxDifference).clamp(0.0, 1.0);
          }
          progress = calcProgress.clamp(0.05, 1.0);
          goalDetailStr = isAchieved
              ? l10n.goalAchieved
              : l10n.remainingWeightLabel(
                  '${displayDifference.toStringAsFixed(1)} $unitLabel',
                );

        case WeightGoalMode.maintain:
          final differenceKg = (currentWeightKg - target).abs();
          final thresholdKg = unit == MeasurementUnit.imperial
              ? lbsToKg(2.2)
              : 1.0;
          isAchieved = differenceKg <= thresholdKg;
          displayDifference = unit == MeasurementUnit.imperial
              ? kgToLbs(differenceKg)
              : differenceKg;
          final maxDifference = unit == MeasurementUnit.imperial ? 10.0 : 5.0;
          double calcProgress = 1.0;
          if (!isAchieved) {
            calcProgress =
                1.0 - (displayDifference / maxDifference).clamp(0.0, 1.0);
          }
          progress = isAchieved ? 1.0 : calcProgress.clamp(0.05, 1.0);
          final rangeDisplay = unit == MeasurementUnit.imperial
              ? '2.0 lb'
              : '1.0 kg';
          final sign = currentWeightKg >= target ? '+' : '-';
          goalDetailStr = isAchieved
              ? l10n.goalWeightMaintained(rangeDisplay)
              : l10n.goalWeightDeviation(
                  '$sign${displayDifference.toStringAsFixed(1)} $unitLabel',
                );
      }

      goalTargetStr = '${displayTarget.toStringAsFixed(1)} $unitLabel';
      semanticsLabel = l10n.goalProgressSemantics(goalTargetStr, goalDetailStr);
    } else {
      isAchieved = false;
      progress = 0.0;
      goalTargetStr = l10n.notSet;
      goalDetailStr = l10n.setGoalAction;
      semanticsLabel = l10n.setGoalSemantics;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final achievedColor = isDark
        ? Colors.green.shade300
        : Colors.green.shade700;
    final accentColor = isAchieved ? achievedColor : colorScheme.primary;

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.goalWeightLabel(goalTargetStr),
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (hasTarget) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      goalDetailStr,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: textTheme.labelMedium?.copyWith(
                        color: isAchieved
                            ? achievedColor
                            : hasTarget
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.primary,
                        fontWeight: isAchieved || !hasTarget
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? achievedColor.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: progress > 0
                    ? FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
