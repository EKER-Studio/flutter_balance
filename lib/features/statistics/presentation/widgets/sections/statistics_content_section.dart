import 'package:flutter/material.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_status_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/habits_activity_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/hero_progress_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/milestones_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/period_comparison_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/weight_range_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';

import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';

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
    final streak = _calculateStreak(entries, now);
    final bestStreak = _calculateBestStreak(entries);
    final compliancePct = _calculateTotalCompliance(entries, now);
    final weeklyPace = calculateWeeklyPace(
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

  /// Computes the average weekly pace (weight change per 7 days) over the given [windowDays].
  ///
  /// Filters entries within `[now - windowDays, now]`.
  /// Returns `null` if fewer than 2 entries exist in that window.
  static double? calculateWeeklyPace(
    List<WeightEntry> entries, {
    int windowDays = 30,
    DateTime? now,
  }) {
    if (entries.length < 2) return null;

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final referenceDate = now ?? DateTime.now();
    final windowStart = referenceDate.subtract(Duration(days: windowDays));

    final recentEntries = sorted
        .where((e) => !e.dateTime.isBefore(windowStart))
        .toList();
    if (recentEntries.length < 2) return null;

    final first = recentEntries.first;
    final last = recentEntries.last;

    final days = last.dateTime.difference(first.dateTime).inDays;
    if (days < 1) return 0.0;

    final weeks = days / 7.0;
    final diffKg = last.weightKg - first.weightKg;

    return diffKg / weeks;
  }

  static int _calculateStreak(List<WeightEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet();

    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = DateTime(now.year, now.month, now.day - 1);

    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayDate) ? todayDate : yesterdayDate;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    return streak;
  }

  static int _calculateTotalCompliance(
    List<WeightEntry> entries,
    DateTime now,
  ) {
    if (entries.isEmpty) return 0;

    final firstDate = entries
        .map((e) => e.dateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);

    int totalDays = today.difference(start).inDays + 1;
    if (totalDays <= 0) totalDays = 1;

    final loggedDays = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;
    return ((loggedDays / totalDays) * 100).round().clamp(0, 100);
  }

  static int _calculateBestStreak(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;

    final dates =
        entries
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

    int best = 1;
    int current = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return best;
  }
}
