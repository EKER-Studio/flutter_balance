import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying overall weight change progress, pace, and goal progress bar.
class HeroProgressCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? targetWeight;
  final double? weeklyPace;
  final MeasurementUnit unit;
  final int paceWindowDays;
  final WeightGoalMode goalMode;
  final VoidCallback? onPaceWindowTap;

  const HeroProgressCard({
    super.key,
    required this.entries,
    required this.targetWeight,
    required this.weeklyPace,
    required this.unit,
    this.paceWindowDays = 30,
    this.goalMode = WeightGoalMode.lose,
    this.onPaceWindowTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final sortedByDate = entries.reversed.toList(); // Ascending date
    final firstEntry = sortedByDate.first;
    final latestEntry = sortedByDate.last;

    final totalChangeKg = latestEntry.weightKg - firstEntry.weightKg;
    final totalChangeDisplay = unit == MeasurementUnit.imperial
        ? kgToLbs(totalChangeKg)
        : totalChangeKg;
    final unitLabel = unitLabelFor(unit);
    final isTotalLoss = totalChangeDisplay < -0.05;
    final isTotalGain = totalChangeDisplay > 0.05;
    final String totalChangeStr;
    if (isTotalGain) {
      totalChangeStr = '+${totalChangeDisplay.toStringAsFixed(1)}';
    } else if (isTotalLoss) {
      totalChangeStr = totalChangeDisplay.toStringAsFixed(1);
    } else {
      totalChangeStr = '0.0';
    }
    final formattedValue = '$totalChangeStr $unitLabel';

    final paceDisplay = weeklyPace != null
        ? (unit == MeasurementUnit.imperial
              ? kgToLbs(weeklyPace!)
              : weeklyPace!)
        : null;
    final isPaceLoss = paceDisplay != null && paceDisplay < -0.05;
    final isPaceGain = paceDisplay != null && paceDisplay > 0.05;
    final String? paceStr = paceDisplay != null
        ? (isPaceGain
              ? '+${paceDisplay.toStringAsFixed(1)}'
              : (isPaceLoss ? paceDisplay.toStringAsFixed(1) : '0.0'))
        : null;
    final paceBadgeText = paceStr != null
        ? l10n.weeklyPaceBadge('$paceStr $unitLabel')
        : null;

    double? goalProgressPct;
    String? statusBadge;
    bool isSuccessBadge = true;

    if (targetWeight != null) {
      switch (goalMode) {
        case WeightGoalMode.lose:
          if (latestEntry.weightKg <= targetWeight!) {
            statusBadge = l10n.goalAchieved;
            goalProgressPct = 100.0;
            isSuccessBadge = true;
          } else {
            final distKg = latestEntry.weightKg - targetWeight!;
            final distDisplay = unit == MeasurementUnit.imperial
                ? kgToLbs(distKg)
                : distKg;
            statusBadge =
                '${distDisplay.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
            isSuccessBadge = false;
            goalProgressPct = _calculateGoalProgressPct(
              startKg: firstEntry.weightKg,
              currentKg: latestEntry.weightKg,
              targetKg: targetWeight!,
              isLosing: true,
            );
          }

        case WeightGoalMode.gain:
          if (latestEntry.weightKg >= targetWeight!) {
            statusBadge = l10n.goalAchieved;
            goalProgressPct = 100.0;
            isSuccessBadge = true;
          } else {
            final distKg = targetWeight! - latestEntry.weightKg;
            final distDisplay = unit == MeasurementUnit.imperial
                ? kgToLbs(distKg)
                : distKg;
            statusBadge =
                '${distDisplay.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
            isSuccessBadge = false;
            goalProgressPct = _calculateGoalProgressPct(
              startKg: firstEntry.weightKg,
              currentKg: latestEntry.weightKg,
              targetKg: targetWeight!,
              isLosing: false,
            );
          }

        case WeightGoalMode.maintain:
          final distKg = (latestEntry.weightKg - targetWeight!).abs();
          final thresholdKg = unit == MeasurementUnit.imperial
              ? lbsToKg(2.2)
              : 1.0;
          final isMaintained = distKg <= thresholdKg;
          final rangeDisplay = unit == MeasurementUnit.imperial
              ? '2.0 lb'
              : '1.0 kg';
          final distDisplay = unit == MeasurementUnit.imperial
              ? kgToLbs(distKg)
              : distKg;
          final sign = latestEntry.weightKg >= targetWeight! ? '+' : '-';
          statusBadge = isMaintained
              ? l10n.goalWeightMaintained(rangeDisplay)
              : l10n.goalWeightDeviation(
                  '$sign${distDisplay.toStringAsFixed(1)} $unitLabel',
                );
          isSuccessBadge = isMaintained;
          final maxDiff = unit == MeasurementUnit.imperial ? 10.0 : 5.0;
          goalProgressPct = isMaintained
              ? 100.0
              : ((1.0 - (distDisplay / maxDiff).clamp(0.0, 1.0)) * 100.0).clamp(
                  5.0,
                  100.0,
                );
      }
    } else {
      if (goalMode == WeightGoalMode.gain && totalChangeKg > 0.05) {
        statusBadge = l10n.greatJob;
      } else if (goalMode == WeightGoalMode.lose && totalChangeKg < -0.05) {
        statusBadge = l10n.greatJob;
      } else if (goalMode == WeightGoalMode.maintain &&
          totalChangeKg.abs() <= 1.0) {
        statusBadge = l10n.greatJob;
      }
    }

    final semanticLabel =
        '${l10n.totalProgress}: $formattedValue${statusBadge != null ? ", $statusBadge" : ""}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = isSuccessBadge
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.orange.withValues(alpha: 0.15);
    final badgeFg = isSuccessBadge
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.orange.shade300 : Colors.orange.shade700);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppAnalytics.logStatisticsHeroProgressCardTapped();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.track_changes_outlined,
                          size: 24,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.totalProgress,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    if (statusBadge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSuccessBadge) ...[
                              Icon(
                                targetWeight != null
                                    ? Icons.check_circle_outline
                                    : Icons.verified_outlined,
                                size: 16,
                                color: badgeFg,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              statusBadge,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: badgeFg,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalChangeStr,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unitLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.sinceEntryDate(
                          _formatEntryDate(context, firstEntry.dateTime, l10n),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (paceBadgeText != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onPaceWindowTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_outlined,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$paceBadgeText (${l10n.paceWindowDays(paceWindowDays)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (onPaceWindowTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (goalProgressPct != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.goalProgress,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        '${goalProgressPct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goalProgressPct / 100.0,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHigh,
                      color: cs.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _calculateGoalProgressPct({
    required double startKg,
    required double currentKg,
    required double targetKg,
    required bool isLosing,
  }) {
    if (startKg == targetKg) return 100.0;

    final totalNeeded = (startKg - targetKg).abs();
    final achieved = isLosing ? (startKg - currentKg) : (currentKg - startKg);

    if (achieved <= 0) return 0.0;

    final pct = (achieved / totalNeeded) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  static String _formatEntryDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return l10n.today;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }
}
