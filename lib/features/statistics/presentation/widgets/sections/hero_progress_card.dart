import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying overall weight change progress, pace, and goal progress bar.
class HeroProgressCard extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? targetWeight;
  final double? weeklyPace;
  final MeasurementUnit unit;

  const HeroProgressCard({
    super.key,
    required this.entries,
    required this.targetWeight,
    required this.weeklyPace,
    required this.unit,
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

    final sign = totalChangeDisplay > 0 ? '+' : '';
    final formattedValue =
        '$sign${totalChangeDisplay.toStringAsFixed(1)} $unitLabel';

    final paceDisplay = weeklyPace != null
        ? (unit == MeasurementUnit.imperial
              ? kgToLbs(weeklyPace!)
              : weeklyPace!)
        : null;
    final paceSign = (paceDisplay != null && paceDisplay > 0) ? '+' : '';
    final paceBadgeText = paceDisplay != null
        ? l10n.weeklyPaceBadge(
            '$paceSign${paceDisplay.toStringAsFixed(1)} $unitLabel',
          )
        : null;

    double? goalProgressPct;
    String? statusBadge;
    bool isSuccessBadge = true;

    if (targetWeight != null) {
      if (latestEntry.weightKg <= targetWeight!) {
        statusBadge = l10n.goalAchieved;
        goalProgressPct = 100.0;
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
        );
      }
    } else if (totalChangeKg < 0) {
      statusBadge = l10n.greatJob;
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
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            size: 24,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.totalProgress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (statusBadge != null) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$sign${totalChangeDisplay.toStringAsFixed(1)}',
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
                  Row(
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
                          paceBadgeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
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
  }) {
    if (startKg == targetKg) return 100.0;

    final totalNeeded = (startKg - targetKg).abs();
    final isLosing = startKg > targetKg;
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
