import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_chart_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/habits_activity_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/hero_progress_card.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/weight_range_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';

/// The responsive content section composing progress, habits, range, and BMI chart cards.
class StatisticsContentSection extends StatelessWidget {
  final List<WeightEntry> entries;
  final List<WeightEntry> filteredEntries;
  final TimePeriod timePeriod;
  final double? heightCm;
  final double? targetWeight;
  final MeasurementUnit unit;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const StatisticsContentSection({
    super.key,
    required this.entries,
    required this.filteredEntries,
    required this.timePeriod,
    required this.heightCm,
    required this.targetWeight,
    required this.unit,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = _calculateStreak(entries, now);
    final compliancePct = _calculateTotalCompliance(entries, now);
    final weeklyPace = _calculateWeeklyPace(entries);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final heroProgressCard = HeroProgressCard(
          entries: entries,
          targetWeight: targetWeight,
          weeklyPace: weeklyPace,
          unit: unit,
        );

        final habitsCard = HabitsActivityCard(
          streak: streak,
          compliancePct: compliancePct,
        );

        final rangeCard = WeightRangeCard(entries: entries, unit: unit);

        final bmiCard = BmiChartCard(
          entries: filteredEntries,
          heightCm: heightCm,
          period: timePeriod,
          onPeriodChanged: onPeriodChanged,
        );

        return ClampedLayout(
          maxWidth: isWide ? 1000 : 600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isWide
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: heroProgressCard),
                        const SizedBox(width: 16),
                        Expanded(child: rangeCard),
                      ],
                    ),
                    const SizedBox(height: 16),
                    habitsCard,
                    const SizedBox(height: 16),
                    bmiCard,
                    const SizedBox(height: 32),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heroProgressCard,
                    const SizedBox(height: 16),
                    habitsCard,
                    const SizedBox(height: 16),
                    rangeCard,
                    const SizedBox(height: 16),
                    bmiCard,
                    const SizedBox(height: 100),
                  ],
                ),
        );
      },
    );
  }

  static double? _calculateWeeklyPace(List<WeightEntry> entries) {
    if (entries.length < 2) return null;

    final sorted = entries.reversed.toList(); // Ascending date
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final recentEntries = sorted
        .where((e) => e.dateTime.isAfter(monthAgo))
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
}
