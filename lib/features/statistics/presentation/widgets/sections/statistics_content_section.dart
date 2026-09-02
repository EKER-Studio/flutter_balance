import 'package:flutter/material.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/domain/services/habits_calculator.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/domain/services/pace_calculator.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_status_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/habits_activity_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/hero_progress_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/milestones_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/period_comparison_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/weight_range_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/core/models/time_period.dart';

import 'package:balance/features/weight/domain/weight_goal_mode.dart';

/// The responsive content section composing progress, habits, range, and BMI status cards.
class StatisticsContentSection extends StatelessWidget {
  final List<WeightEntry> entries;
  final List<WeightEntry> filteredEntries;
  final TimePeriod timePeriod;
  final double? heightCm;
  final double? targetWeight;
  final WeightGoalMode goalMode;
  final MeasurementUnit unit;
  final int weeklyPaceWindowDays;
  final ValueChanged<TimePeriod> onPeriodChanged;
  final VoidCallback? onPaceWindowTap;

  const StatisticsContentSection({
    super.key,
    required this.entries,
    required this.filteredEntries,
    required this.timePeriod,
    required this.heightCm,
    required this.targetWeight,
    this.goalMode = WeightGoalMode.lose,
    required this.unit,
    this.weeklyPaceWindowDays = 30,
    required this.onPeriodChanged,
    this.onPaceWindowTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = HabitsCalculator.calculateStreak(entries, now);
    final bestStreak = HabitsCalculator.calculateBestStreak(entries);
    final compliancePct = HabitsCalculator.calculateTotalCompliance(
      entries,
      now,
    );
    final weeklyPace = PaceCalculator.calculateWeeklyPace(
      entries,
      windowDays: weeklyPaceWindowDays,
      now: now,
    );
    final milestones = MilestoneCalculator.evaluate(
      entries: entries,
      targetWeight: targetWeight,
      heightCm: heightCm,
      goalMode: goalMode,
    );
    final isWide = context.isMultiColumn;

    final heroProgressCard = HeroProgressCard(
      entries: entries,
      targetWeight: targetWeight,
      weeklyPace: weeklyPace,
      unit: unit,
      paceWindowDays: weeklyPaceWindowDays,
      goalMode: goalMode,
      onPaceWindowTap: onPaceWindowTap,
    );

    final milestonesCard = MilestonesCard(milestones: milestones);
    final comparisonCard = PeriodComparisonCard(entries: entries, unit: unit);

    final bmiCard = BmiStatusCard(
      entries: entries,
      heightCm: heightCm,
      unit: unit,
    );

    final habitsCard = HabitsActivityCard(
      streak: streak,
      bestStreak: bestStreak,
      compliancePct: compliancePct,
    );

    final rangeCard = WeightRangeCard(entries: entries, unit: unit);

    return isWide
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heroProgressCard,
              const SizedBox(height: 16),
              milestonesCard,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: bmiCard),
                  const SizedBox(width: 16),
                  Expanded(child: comparisonCard),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: habitsCard),
                  const SizedBox(width: 16),
                  Expanded(child: rangeCard),
                ],
              ),
              const SizedBox(height: 32),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heroProgressCard,
              const SizedBox(height: 16),
              milestonesCard,
              const SizedBox(height: 16),
              bmiCard,
              const SizedBox(height: 16),
              comparisonCard,
              const SizedBox(height: 16),
              habitsCard,
              const SizedBox(height: 16),
              rangeCard,
              const SizedBox(height: 100),
            ],
          );
  }
}
