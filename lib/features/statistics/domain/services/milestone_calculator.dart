import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A service computing user achievements and milestone progression from weight history.
class MilestoneCalculator {
  const MilestoneCalculator._();

  /// Evaluates all milestones based on recorded entries, height, and target weight.
  ///
  /// @param entries The full list of weight measurements.
  /// @param targetWeight The user's configured goal weight in kg, if any.
  /// @param heightCm The user's configured height in centimeters, if any.
  /// @return A list of evaluated [Milestone] instances in display order.
  static List<Milestone> evaluate({
    required List<WeightEntry> entries,
    double? targetWeight,
    double? heightCm,
  }) {
    if (entries.isEmpty) {
      return _emptyMilestones(targetWeight: targetWeight, heightCm: heightCm);
    }

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstEntry = sorted.first;
    final startWeight = firstEntry.weightKg;

    // Calculate maximum historical streak
    final uniqueDates =
        sorted
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort();

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? prevDate;
    DateTime? streak7Date;
    DateTime? streak30Date;
    DateTime? streak100Date;

    for (final date in uniqueDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }
      prevDate = date;

      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      if (currentStreak >= 7 && streak7Date == null) streak7Date = date;
      if (currentStreak >= 30 && streak30Date == null) streak30Date = date;
      if (currentStreak >= 100 && streak100Date == null) streak100Date = date;
    }

    // Weight loss milestones
    double minWeight = startWeight;
    DateTime? loss1Date;
    DateTime? loss5Date;
    DateTime? loss10Date;

    for (final entry in sorted) {
      if (entry.weightKg < minWeight) {
        minWeight = entry.weightKg;
      }
      final loss = startWeight - minWeight;
      if (loss >= 1.0 && loss1Date == null) loss1Date = entry.dateTime;
      if (loss >= 5.0 && loss5Date == null) loss5Date = entry.dateTime;
      if (loss >= 10.0 && loss10Date == null) loss10Date = entry.dateTime;
    }

    final maxLoss = math.max(0.0, startWeight - minWeight);

    // Goal milestones
    bool isHalfway = false;
    bool isReached = false;
    double halfwayProgress = 0.0;
    double reachedProgress = 0.0;
    DateTime? halfwayDate;
    DateTime? reachedDate;

    if (targetWeight != null) {
      final totalToLose = startWeight - targetWeight;
      if (totalToLose <= 0) {
        // Target is same or higher than start
        isHalfway = true;
        isReached = true;
        halfwayProgress = 1.0;
        reachedProgress = 1.0;
        halfwayDate = firstEntry.dateTime;
        reachedDate = firstEntry.dateTime;
      } else {
        final progressFraction = (maxLoss / totalToLose).clamp(0.0, 1.0);
        halfwayProgress = (progressFraction / 0.5).clamp(0.0, 1.0);
        reachedProgress = progressFraction;
        isHalfway = progressFraction >= 0.5;
        isReached = progressFraction >= 1.0;

        for (final entry in sorted) {
          final loss = startWeight - entry.weightKg;
          if (loss >= totalToLose * 0.5 && halfwayDate == null) {
            halfwayDate = entry.dateTime;
          }
          if (entry.weightKg <= targetWeight && reachedDate == null) {
            reachedDate = entry.dateTime;
          }
        }
      }
    }

    // Healthy BMI milestone
    bool isHealthyBmi = false;
    double healthyBmiProgress = 0.0;
    DateTime? healthyBmiDate;

    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      for (final entry in sorted) {
        final bmi = entry.weightKg / (heightM * heightM);
        if (bmi >= 18.5 && bmi <= 24.9) {
          isHealthyBmi = true;
          healthyBmiProgress = 1.0;
          healthyBmiDate ??= entry.dateTime;
        }
      }

      if (!isHealthyBmi) {
        final latestBmi = sorted.last.weightKg / (heightM * heightM);
        if (latestBmi > 24.9) {
          final startBmi = startWeight / (heightM * heightM);
          if (startBmi > 24.9) {
            final targetBmiDiff = startBmi - 24.9;
            final achievedBmiDiff = math.max(0.0, startBmi - latestBmi);
            healthyBmiProgress = (achievedBmiDiff / targetBmiDiff).clamp(
              0.0,
              1.0,
            );
          }
        } else if (latestBmi < 18.5) {
          final startBmi = startWeight / (heightM * heightM);
          if (startBmi < 18.5) {
            final targetBmiDiff = 18.5 - startBmi;
            final achievedBmiDiff = math.max(0.0, latestBmi - startBmi);
            healthyBmiProgress = (achievedBmiDiff / targetBmiDiff).clamp(
              0.0,
              1.0,
            );
          }
        }
      }
    }

    return [
      Milestone(
        type: MilestoneType.firstEntry,
        icon: Icons.flag_outlined,
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: firstEntry.dateTime,
      ),
      Milestone(
        type: MilestoneType.streak7,
        icon: Icons.local_fire_department_outlined,
        isUnlocked: maxStreak >= 7,
        progress: (maxStreak / 7.0).clamp(0.0, 1.0),
        unlockedDate: streak7Date,
      ),
      Milestone(
        type: MilestoneType.streak30,
        icon: Icons.calendar_month_outlined,
        isUnlocked: maxStreak >= 30,
        progress: (maxStreak / 30.0).clamp(0.0, 1.0),
        unlockedDate: streak30Date,
      ),
      Milestone(
        type: MilestoneType.streak100,
        icon: Icons.workspace_premium_outlined,
        isUnlocked: maxStreak >= 100,
        progress: (maxStreak / 100.0).clamp(0.0, 1.0),
        unlockedDate: streak100Date,
      ),
      Milestone(
        type: MilestoneType.weightLoss1kg,
        icon: Icons.trending_down_outlined,
        isUnlocked: maxLoss >= 1.0,
        progress: (maxLoss / 1.0).clamp(0.0, 1.0),
        unlockedDate: loss1Date,
      ),
      Milestone(
        type: MilestoneType.weightLoss5kg,
        icon: Icons.fitness_center_outlined,
        isUnlocked: maxLoss >= 5.0,
        progress: (maxLoss / 5.0).clamp(0.0, 1.0),
        unlockedDate: loss5Date,
      ),
      Milestone(
        type: MilestoneType.weightLoss10kg,
        icon: Icons.military_tech_outlined,
        isUnlocked: maxLoss >= 10.0,
        progress: (maxLoss / 10.0).clamp(0.0, 1.0),
        unlockedDate: loss10Date,
      ),
      if (targetWeight != null) ...[
        Milestone(
          type: MilestoneType.goalHalfway,
          icon: Icons.timeline_outlined,
          isUnlocked: isHalfway,
          progress: halfwayProgress,
          unlockedDate: halfwayDate,
        ),
        Milestone(
          type: MilestoneType.goalReached,
          icon: Icons.emoji_events_outlined,
          isUnlocked: isReached,
          progress: reachedProgress,
          unlockedDate: reachedDate,
        ),
      ],
      if (heightCm != null && heightCm > 0)
        Milestone(
          type: MilestoneType.healthyBmi,
          icon: Icons.favorite_outline,
          isUnlocked: isHealthyBmi,
          progress: healthyBmiProgress,
          unlockedDate: healthyBmiDate,
        ),
    ];
  }

  static List<Milestone> _emptyMilestones({
    double? targetWeight,
    double? heightCm,
  }) {
    return [
      const Milestone(
        type: MilestoneType.firstEntry,
        icon: Icons.flag_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak7,
        icon: Icons.local_fire_department_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak30,
        icon: Icons.calendar_month_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak100,
        icon: Icons.workspace_premium_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.weightLoss1kg,
        icon: Icons.trending_down_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.weightLoss5kg,
        icon: Icons.fitness_center_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.weightLoss10kg,
        icon: Icons.military_tech_outlined,
        isUnlocked: false,
        progress: 0.0,
      ),
      if (targetWeight != null) ...[
        const Milestone(
          type: MilestoneType.goalHalfway,
          icon: Icons.timeline_outlined,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.goalReached,
          icon: Icons.emoji_events_outlined,
          isUnlocked: false,
          progress: 0.0,
        ),
      ],
      if (heightCm != null && heightCm > 0)
        const Milestone(
          type: MilestoneType.healthyBmi,
          icon: Icons.favorite_outline,
          isUnlocked: false,
          progress: 0.0,
        ),
    ];
  }
}
