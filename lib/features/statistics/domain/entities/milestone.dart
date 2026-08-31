import 'package:flutter/material.dart';

/// The specific milestone or achievement identifier.
enum MilestoneType {
  firstEntry,
  streak7,
  streak30,
  streak100,
  weightLoss1kg,
  weightLoss5kg,
  weightLoss10kg,
  weightGain1kg,
  weightGain5kg,
  weightGain10kg,
  goalHalfway,
  goalReached,
  healthyBmi,
}

/// A domain entity representing a milestone achievement.
class Milestone {
  /// The specific type of the milestone.
  final MilestoneType type;

  /// The icon representing the achievement.
  final IconData icon;

  /// Whether the milestone conditions have been fulfilled.
  final bool isUnlocked;

  /// The progress toward unlocking this milestone, clamped between 0.0 and 1.0.
  final double progress;

  /// The timestamp when the milestone was first unlocked, if available.
  final DateTime? unlockedDate;

  const Milestone({
    required this.type,
    required this.icon,
    required this.isUnlocked,
    required this.progress,
    this.unlockedDate,
  });

  Milestone copyWith({
    MilestoneType? type,
    IconData? icon,
    bool? isUnlocked,
    double? progress,
    DateTime? unlockedDate,
  }) {
    return Milestone(
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}
