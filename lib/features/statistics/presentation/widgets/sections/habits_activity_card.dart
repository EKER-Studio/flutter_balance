import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/presentation/widgets/components/weight_detail_row.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying logging streak metrics and compliance percentage
/// in a 3-row layout identical to [WeightRangeCard].
class HabitsActivityCard extends StatelessWidget {
  /// Current consecutive logging streak in days.
  final int streak;

  /// Best (longest) consecutive logging streak in days.
  final int bestStreak;

  /// Overall logging compliance percentage.
  final int compliancePct;

  const HabitsActivityCard({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.compliancePct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label:
          '${l10n.currentStreak}: ${l10n.streakDays(streak)}, '
          '${l10n.bestStreak}: ${l10n.streakDays(bestStreak)}, '
          '${l10n.monthlyCompliance}: $compliancePct%',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppAnalytics.logStatisticsHabitsCardTapped();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeightDetailRow(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: cs.primary,
                  label: l10n.currentStreak,
                  value: l10n.streakDays(streak),
                  date: '',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                WeightDetailRow(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: cs.primary,
                  label: l10n.bestStreak,
                  value: l10n.streakDays(bestStreak),
                  date: '',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                WeightDetailRow(
                  icon: Icons.auto_graph_outlined,
                  iconColor: cs.primary,
                  label: l10n.monthlyCompliance,
                  value: '$compliancePct%',
                  date: l10n.allEntriesLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
