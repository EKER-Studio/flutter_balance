import 'dart:math' as math;
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A service computing user achievements and milestone progression from weight history.
class MilestoneCalculator {
  const MilestoneCalculator._();

  /// Evaluates all milestones based on recorded entries, height, target weight, and goal mode.
  ///
  /// @param entries The full list of weight measurements.
  /// @param targetWeight The user's configured goal weight in kg, if any.
  /// @param heightCm The user's configured height in centimeters, if any.
  /// @param goalMode The user's goal mode (lose, maintain, gain).
  /// @return A list of evaluated [Milestone] instances in display order.
  static List<Milestone> evaluate({
    required List<WeightEntry> entries,
    double? targetWeight,
    double? heightCm,
    WeightGoalMode goalMode = WeightGoalMode.lose,
  }) {
    if (entries.isEmpty) {
      return _emptyMilestones(
        targetWeight: targetWeight,
        heightCm: heightCm,
        goalMode: goalMode,
      );
    }

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final firstEntry = sorted.first;
    final startWeight = firstEntry.weightKg;

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
    DateTime? streak365Date;
    DateTime? comebackDate;
    bool hasComeback = false;

    for (final date in uniqueDates) {
      if (prevDate == null) {
        currentStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          if (diff > 14) {
            hasComeback = true;
            comebackDate ??= date;
          }
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
      if (currentStreak >= 365 && streak365Date == null) streak365Date = date;
    }

    double minWeight = startWeight;
    double maxWeight = startWeight;
    DateTime? loss1Date;
    DateTime? loss5Date;
    DateTime? loss10Date;
    DateTime? loss15Date;
    DateTime? loss20Date;
    DateTime? gain1Date;
    DateTime? gain5Date;
    DateTime? gain10Date;
    DateTime? gain15Date;
    DateTime? gain20Date;
    DateTime? earlyBirdDate;
    DateTime? nightOwlDate;
    DateTime? newYearDate;
    DateTime? yearEndDate;

    for (final entry in sorted) {
      if (entry.weightKg < minWeight) {
        minWeight = entry.weightKg;
      }
      if (entry.weightKg > maxWeight) {
        maxWeight = entry.weightKg;
      }
      final loss = startWeight - entry.weightKg;
      final gain = entry.weightKg - startWeight;
      if (loss >= 1.0 && loss1Date == null) loss1Date = entry.dateTime;
      if (loss >= 5.0 && loss5Date == null) loss5Date = entry.dateTime;
      if (loss >= 10.0 && loss10Date == null) loss10Date = entry.dateTime;
      if (loss >= 15.0 && loss15Date == null) loss15Date = entry.dateTime;
      if (loss >= 20.0 && loss20Date == null) loss20Date = entry.dateTime;
      if (gain >= 1.0 && gain1Date == null) gain1Date = entry.dateTime;
      if (gain >= 5.0 && gain5Date == null) gain5Date = entry.dateTime;
      if (gain >= 10.0 && gain10Date == null) gain10Date = entry.dateTime;
      if (gain >= 15.0 && gain15Date == null) gain15Date = entry.dateTime;
      if (gain >= 20.0 && gain20Date == null) gain20Date = entry.dateTime;

      if (entry.dateTime.hour < 8 && earlyBirdDate == null) {
        earlyBirdDate = entry.dateTime;
      }
      if (entry.dateTime.hour >= 22 && nightOwlDate == null) {
        nightOwlDate = entry.dateTime;
      }
      if (entry.dateTime.month == 1 &&
          entry.dateTime.day == 1 &&
          newYearDate == null) {
        newYearDate = entry.dateTime;
      }
      if (entry.dateTime.month == 12 &&
          entry.dateTime.day == 31 &&
          yearEndDate == null) {
        yearEndDate = entry.dateTime;
      }
    }

    // Weekend Warrior evaluation (4 consecutive weekends)
    final weekendSaturdays = <DateTime>{};
    for (final date in uniqueDates) {
      if (date.weekday == DateTime.saturday) {
        weekendSaturdays.add(date);
      } else if (date.weekday == DateTime.sunday) {
        weekendSaturdays.add(date.subtract(const Duration(days: 1)));
      }
    }
    final sortedWeekendSaturdays = weekendSaturdays.toList()..sort();
    int currentWeekendStreak = 0;
    int maxWeekendStreak = 0;
    DateTime? prevWeekendSat;
    DateTime? weekendWarriorDate;

    for (final sat in sortedWeekendSaturdays) {
      if (prevWeekendSat == null) {
        currentWeekendStreak = 1;
      } else {
        final diff = sat.difference(prevWeekendSat).inDays;
        if (diff == 7) {
          currentWeekendStreak++;
        } else {
          currentWeekendStreak = 1;
        }
      }
      prevWeekendSat = sat;
      if (currentWeekendStreak > maxWeekendStreak) {
        maxWeekendStreak = currentWeekendStreak;
      }
      if (currentWeekendStreak >= 4 && weekendWarriorDate == null) {
        weekendWarriorDate = sat;
      }
    }

    final maxLoss = math.max(0.0, startWeight - minWeight);
    final maxGain = math.max(0.0, maxWeight - startWeight);

    bool isHalfway = false;
    bool isReached = false;
    double halfwayProgress = 0.0;
    double reachedProgress = 0.0;
    DateTime? halfwayDate;
    DateTime? reachedDate;

    if (targetWeight != null) {
      if (goalMode == WeightGoalMode.gain) {
        final totalToGain = targetWeight - startWeight;
        if (totalToGain <= 0) {
          isHalfway = true;
          isReached = true;
          halfwayProgress = 1.0;
          reachedProgress = 1.0;
          halfwayDate = firstEntry.dateTime;
          reachedDate = firstEntry.dateTime;
        } else {
          final progressFraction = (maxGain / totalToGain).clamp(0.0, 1.0);
          halfwayProgress = (progressFraction / 0.5).clamp(0.0, 1.0);
          reachedProgress = progressFraction;
          isHalfway = progressFraction >= 0.5;
          isReached = progressFraction >= 1.0;

          for (final entry in sorted) {
            final gain = entry.weightKg - startWeight;
            if (gain >= totalToGain * 0.5 && halfwayDate == null) {
              halfwayDate = entry.dateTime;
            }
            if (entry.weightKg >= targetWeight && reachedDate == null) {
              reachedDate = entry.dateTime;
            }
          }
        }
      } else if (goalMode == WeightGoalMode.maintain) {
        final latestWeight = sorted.last.weightKg;
        final diff = (latestWeight - targetWeight).abs();
        isReached = diff <= 1.0;
        reachedProgress = isReached
            ? 1.0
            : (1.0 - (diff / 5.0)).clamp(0.0, 1.0);
        isHalfway = diff <= 2.5;
        halfwayProgress = isHalfway
            ? 1.0
            : (1.0 - (diff / 5.0)).clamp(0.0, 1.0);
        if (isReached) reachedDate = sorted.last.dateTime;
        if (isHalfway) halfwayDate = sorted.last.dateTime;
      } else {
        final totalToLose = startWeight - targetWeight;
        if (totalToLose <= 0) {
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
    }

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

    final isGain = goalMode == WeightGoalMode.gain;

    return [
      Milestone(
        type: MilestoneType.firstEntry,
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: firstEntry.dateTime,
      ),
      Milestone(
        type: MilestoneType.streak7,
        isUnlocked: maxStreak >= 7,
        progress: (maxStreak / 7.0).clamp(0.0, 1.0),
        unlockedDate: streak7Date,
      ),
      Milestone(
        type: MilestoneType.streak30,
        isUnlocked: maxStreak >= 30,
        progress: (maxStreak / 30.0).clamp(0.0, 1.0),
        unlockedDate: streak30Date,
      ),
      Milestone(
        type: MilestoneType.streak100,
        isUnlocked: maxStreak >= 100,
        progress: (maxStreak / 100.0).clamp(0.0, 1.0),
        unlockedDate: streak100Date,
      ),
      Milestone(
        type: MilestoneType.streak365,
        isUnlocked: maxStreak >= 365,
        progress: (maxStreak / 365.0).clamp(0.0, 1.0),
        unlockedDate: streak365Date,
      ),
      Milestone(
        type: MilestoneType.comeback,
        isUnlocked: hasComeback,
        progress: hasComeback ? 1.0 : 0.0,
        unlockedDate: comebackDate,
      ),
      if (isGain) ...[
        Milestone(
          type: MilestoneType.weightGain1kg,
          isUnlocked: maxGain >= 1.0,
          progress: (maxGain / 1.0).clamp(0.0, 1.0),
          unlockedDate: gain1Date,
        ),
        Milestone(
          type: MilestoneType.weightGain5kg,
          isUnlocked: maxGain >= 5.0,
          progress: (maxGain / 5.0).clamp(0.0, 1.0),
          unlockedDate: gain5Date,
        ),
        Milestone(
          type: MilestoneType.weightGain10kg,
          isUnlocked: maxGain >= 10.0,
          progress: (maxGain / 10.0).clamp(0.0, 1.0),
          unlockedDate: gain10Date,
        ),
        Milestone(
          type: MilestoneType.weightGain15kg,
          isUnlocked: maxGain >= 15.0,
          progress: (maxGain / 15.0).clamp(0.0, 1.0),
          unlockedDate: gain15Date,
        ),
        Milestone(
          type: MilestoneType.weightGain20kg,
          isUnlocked: maxGain >= 20.0,
          progress: (maxGain / 20.0).clamp(0.0, 1.0),
          unlockedDate: gain20Date,
        ),
      ] else ...[
        Milestone(
          type: MilestoneType.weightLoss1kg,
          isUnlocked: maxLoss >= 1.0,
          progress: (maxLoss / 1.0).clamp(0.0, 1.0),
          unlockedDate: loss1Date,
        ),
        Milestone(
          type: MilestoneType.weightLoss5kg,
          isUnlocked: maxLoss >= 5.0,
          progress: (maxLoss / 5.0).clamp(0.0, 1.0),
          unlockedDate: loss5Date,
        ),
        Milestone(
          type: MilestoneType.weightLoss10kg,
          isUnlocked: maxLoss >= 10.0,
          progress: (maxLoss / 10.0).clamp(0.0, 1.0),
          unlockedDate: loss10Date,
        ),
        Milestone(
          type: MilestoneType.weightLoss15kg,
          isUnlocked: maxLoss >= 15.0,
          progress: (maxLoss / 15.0).clamp(0.0, 1.0),
          unlockedDate: loss15Date,
        ),
        Milestone(
          type: MilestoneType.weightLoss20kg,
          isUnlocked: maxLoss >= 20.0,
          progress: (maxLoss / 20.0).clamp(0.0, 1.0),
          unlockedDate: loss20Date,
        ),
      ],
      if (targetWeight != null) ...[
        Milestone(
          type: MilestoneType.goalHalfway,
          isUnlocked: isHalfway,
          progress: halfwayProgress,
          unlockedDate: halfwayDate,
        ),
        Milestone(
          type: MilestoneType.goalReached,
          isUnlocked: isReached,
          progress: reachedProgress,
          unlockedDate: reachedDate,
        ),
      ],
      if (heightCm != null && heightCm > 0)
        Milestone(
          type: MilestoneType.healthyBmi,
          isUnlocked: isHealthyBmi,
          progress: healthyBmiProgress,
          unlockedDate: healthyBmiDate,
        ),
      Milestone(
        type: MilestoneType.earlyBird,
        isUnlocked: earlyBirdDate != null,
        progress: earlyBirdDate != null ? 1.0 : 0.0,
        unlockedDate: earlyBirdDate,
      ),
      Milestone(
        type: MilestoneType.nightOwl,
        isUnlocked: nightOwlDate != null,
        progress: nightOwlDate != null ? 1.0 : 0.0,
        unlockedDate: nightOwlDate,
      ),
      Milestone(
        type: MilestoneType.newYear,
        isUnlocked: newYearDate != null,
        progress: newYearDate != null ? 1.0 : 0.0,
        unlockedDate: newYearDate,
      ),
      Milestone(
        type: MilestoneType.yearEnd,
        isUnlocked: yearEndDate != null,
        progress: yearEndDate != null ? 1.0 : 0.0,
        unlockedDate: yearEndDate,
      ),
      Milestone(
        type: MilestoneType.weekendWarrior,
        isUnlocked: maxWeekendStreak >= 4,
        progress: (maxWeekendStreak / 4.0).clamp(0.0, 1.0),
        unlockedDate: weekendWarriorDate,
      ),
    ];
  }

  static List<Milestone> _emptyMilestones({
    double? targetWeight,
    double? heightCm,
    WeightGoalMode goalMode = WeightGoalMode.lose,
  }) {
    final isGain = goalMode == WeightGoalMode.gain;
    return [
      const Milestone(
        type: MilestoneType.firstEntry,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak7,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak30,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak100,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.streak365,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.comeback,
        isUnlocked: false,
        progress: 0.0,
      ),
      if (isGain) ...[
        const Milestone(
          type: MilestoneType.weightGain1kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightGain5kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightGain10kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightGain15kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightGain20kg,
          isUnlocked: false,
          progress: 0.0,
        ),
      ] else ...[
        const Milestone(
          type: MilestoneType.weightLoss1kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightLoss5kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightLoss10kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightLoss15kg,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.weightLoss20kg,
          isUnlocked: false,
          progress: 0.0,
        ),
      ],
      if (targetWeight != null) ...[
        const Milestone(
          type: MilestoneType.goalHalfway,
          isUnlocked: false,
          progress: 0.0,
        ),
        const Milestone(
          type: MilestoneType.goalReached,
          isUnlocked: false,
          progress: 0.0,
        ),
      ],
      if (heightCm != null && heightCm > 0)
        const Milestone(
          type: MilestoneType.healthyBmi,
          isUnlocked: false,
          progress: 0.0,
        ),
      const Milestone(
        type: MilestoneType.earlyBird,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.nightOwl,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.newYear,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.yearEnd,
        isUnlocked: false,
        progress: 0.0,
      ),
      const Milestone(
        type: MilestoneType.weekendWarrior,
        isUnlocked: false,
        progress: 0.0,
      ),
    ];
  }
}
