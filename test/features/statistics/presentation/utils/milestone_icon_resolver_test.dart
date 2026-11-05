import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_icon_resolver.dart';

void main() {
  group('MilestoneIconResolver (iconForMilestone)', () {
    test('maps all MilestoneType values to valid non-null IconData', () {
      for (final type in MilestoneType.values) {
        final icon = iconForMilestone(type);
        expect(icon, isNotNull);
        expect(icon.fontFamily, equals('MaterialIcons'));
      }
    });

    test('verifies specific milestone iconic mappings', () {
      expect(
        iconForMilestone(MilestoneType.firstEntry),
        equals(Icons.flag_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.streak7),
        equals(Icons.local_fire_department_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.streak30),
        equals(Icons.calendar_month_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.weightLoss1kg),
        equals(Icons.trending_down_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.weightGain1kg),
        equals(Icons.trending_up_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.healthyBmi),
        equals(Icons.favorite_outline),
      );
      expect(
        iconForMilestone(MilestoneType.goalReached),
        equals(Icons.stars_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.earlyBird),
        equals(Icons.wb_sunny_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.nightOwl),
        equals(Icons.bedtime_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.newYear),
        equals(Icons.celebration_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.yearEnd),
        equals(Icons.wine_bar_outlined),
      );
      expect(
        iconForMilestone(MilestoneType.weekendWarrior),
        equals(Icons.weekend_outlined),
      );
    });
  });
}
