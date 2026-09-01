/// The grouping category for achievements.
enum MilestoneCategory {
  /// Goals and weight progression achievements.
  goals,

  /// Streaks and consistency habits.
  streaks,

  /// Time-of-day and routine logging achievements.
  routines,

  /// Special calendar days and seasonal milestones.
  special,
}

/// The specific milestone or achievement identifier.
enum MilestoneType {
  firstEntry,
  streak7,
  streak30,
  streak100,
  streak365,
  comeback,
  weightLoss1kg,
  weightLoss5kg,
  weightLoss10kg,
  weightLoss15kg,
  weightLoss20kg,
  weightGain1kg,
  weightGain5kg,
  weightGain10kg,
  weightGain15kg,
  weightGain20kg,
  goalHalfway,
  goalReached,
  healthyBmi,
  earlyBird,
  nightOwl,
  newYear,
  yearEnd,
  weekendWarrior;

  /// Returns the semantic [MilestoneCategory] this milestone belongs to.
  MilestoneCategory get category => switch (this) {
    MilestoneType.firstEntry ||
    MilestoneType.weightLoss1kg ||
    MilestoneType.weightLoss5kg ||
    MilestoneType.weightLoss10kg ||
    MilestoneType.weightLoss15kg ||
    MilestoneType.weightLoss20kg ||
    MilestoneType.weightGain1kg ||
    MilestoneType.weightGain5kg ||
    MilestoneType.weightGain10kg ||
    MilestoneType.weightGain15kg ||
    MilestoneType.weightGain20kg ||
    MilestoneType.goalHalfway ||
    MilestoneType.goalReached ||
    MilestoneType.healthyBmi => MilestoneCategory.goals,
    MilestoneType.streak7 ||
    MilestoneType.streak30 ||
    MilestoneType.streak100 ||
    MilestoneType.streak365 ||
    MilestoneType.comeback => MilestoneCategory.streaks,
    MilestoneType.earlyBird ||
    MilestoneType.nightOwl => MilestoneCategory.routines,
    MilestoneType.newYear ||
    MilestoneType.yearEnd ||
    MilestoneType.weekendWarrior => MilestoneCategory.special,
  };
}

/// A domain entity representing a milestone achievement.
class Milestone {
  /// The specific type of the milestone.
  final MilestoneType type;

  /// Whether the milestone conditions have been fulfilled.
  final bool isUnlocked;

  /// The progress toward unlocking this milestone, clamped between 0.0 and 1.0.
  final double progress;

  /// The timestamp when the milestone was first unlocked, if available.
  final DateTime? unlockedDate;

  const Milestone({
    required this.type,
    required this.isUnlocked,
    required this.progress,
    this.unlockedDate,
  });

  Milestone copyWith({
    MilestoneType? type,
    bool? isUnlocked,
    double? progress,
    DateTime? unlockedDate,
  }) {
    return Milestone(
      type: type ?? this.type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}
