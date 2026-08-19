import 'package:flutter/material.dart';
import 'package:balance/features/statistics/presentation/widgets/components/habit_metric_item.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card section displaying the current logging streak and monthly compliance percentage.
class HabitsActivityCard extends StatelessWidget {
  /// The current streak of consecutive days logged.
  final int streak;

  /// The percentage of days logged over the tracking timeframe.
  final int compliancePct;

  /// Creates a [HabitsActivityCard] widget.
  const HabitsActivityCard({
    super.key,
    required this.streak,
    required this.compliancePct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label:
          '${l10n.loggingStreak}: ${l10n.streakDays(streak)}, ${l10n.monthlyCompliance}: $compliancePct%',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: HabitMetricItem(
                  icon: Icons.local_fire_department,
                  iconColor: cs.primary,
                  label: l10n.loggingStreak,
                  value: l10n.streakDays(streak),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 36,
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: HabitMetricItem(
                  icon: Icons.insights,
                  iconColor: cs.primary,
                  label: l10n.monthlyCompliance,
                  value: '$compliancePct%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
