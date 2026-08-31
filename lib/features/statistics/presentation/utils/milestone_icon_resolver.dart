import 'package:flutter/material.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';

/// Maps a [MilestoneType] to its visual [IconData] representation.
///
/// Keeps Flutter-framework dependencies in the presentation layer,
/// out of the pure-Dart domain entity.
IconData iconForMilestone(MilestoneType type) => switch (type) {
  MilestoneType.firstEntry => Icons.flag_outlined,
  MilestoneType.streak7 => Icons.local_fire_department_outlined,
  MilestoneType.streak30 => Icons.calendar_month_outlined,
  MilestoneType.streak100 => Icons.workspace_premium_outlined,
  MilestoneType.weightLoss1kg => Icons.trending_down_outlined,
  MilestoneType.weightLoss5kg => Icons.fitness_center_outlined,
  MilestoneType.weightLoss10kg => Icons.military_tech_outlined,
  MilestoneType.weightGain1kg => Icons.trending_up_outlined,
  MilestoneType.weightGain5kg => Icons.fitness_center_outlined,
  MilestoneType.weightGain10kg => Icons.military_tech_outlined,
  MilestoneType.goalHalfway => Icons.timeline_outlined,
  MilestoneType.goalReached => Icons.emoji_events_outlined,
  MilestoneType.healthyBmi => Icons.favorite_outline,
};
