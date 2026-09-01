import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';

void main() {
  group('Milestone Entity Tests', () {
    test('instantiates with all fields correctly', () {
      final now = DateTime(2026, 6, 1, 10, 0);
      final milestone = Milestone(
        type: MilestoneType.firstEntry,
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: now,
      );

      expect(milestone.type, MilestoneType.firstEntry);
      expect(milestone.isUnlocked, isTrue);
      expect(milestone.progress, 1.0);
      expect(milestone.unlockedDate, now);
    });

    test('copyWith modifies specified fields while retaining others', () {
      final initialDate = DateTime(2026, 5, 1);
      final newDate = DateTime(2026, 6, 1);

      final milestone = Milestone(
        type: MilestoneType.streak7,
        isUnlocked: false,
        progress: 0.5,
        unlockedDate: initialDate,
      );

      final updated = milestone.copyWith(
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: newDate,
      );

      expect(updated.type, MilestoneType.streak7);
      expect(updated.isUnlocked, isTrue);
      expect(updated.progress, 1.0);
      expect(updated.unlockedDate, newDate);
    });

    test(
      'copyWith returns identical instance values when no arguments provided',
      () {
        final date = DateTime(2026, 5, 1);
        final milestone = Milestone(
          type: MilestoneType.healthyBmi,
          isUnlocked: true,
          progress: 1.0,
          unlockedDate: date,
        );

        final updated = milestone.copyWith();

        expect(updated.type, milestone.type);
        expect(updated.isUnlocked, milestone.isUnlocked);
        expect(updated.progress, milestone.progress);
        expect(updated.unlockedDate, milestone.unlockedDate);
      },
    );

    test('MilestoneType enum contains all expected achievement variants', () {
      expect(MilestoneType.values, contains(MilestoneType.firstEntry));
      expect(MilestoneType.values, contains(MilestoneType.streak7));
      expect(MilestoneType.values, contains(MilestoneType.streak30));
      expect(MilestoneType.values, contains(MilestoneType.streak100));
      expect(MilestoneType.values, contains(MilestoneType.streak365));
      expect(MilestoneType.values, contains(MilestoneType.comeback));
      expect(MilestoneType.values, contains(MilestoneType.weightLoss1kg));
      expect(MilestoneType.values, contains(MilestoneType.weightLoss5kg));
      expect(MilestoneType.values, contains(MilestoneType.weightLoss10kg));
      expect(MilestoneType.values, contains(MilestoneType.weightLoss15kg));
      expect(MilestoneType.values, contains(MilestoneType.weightLoss20kg));
      expect(MilestoneType.values, contains(MilestoneType.weightGain1kg));
      expect(MilestoneType.values, contains(MilestoneType.weightGain5kg));
      expect(MilestoneType.values, contains(MilestoneType.weightGain10kg));
      expect(MilestoneType.values, contains(MilestoneType.weightGain15kg));
      expect(MilestoneType.values, contains(MilestoneType.weightGain20kg));
      expect(MilestoneType.values, contains(MilestoneType.goalHalfway));
      expect(MilestoneType.values, contains(MilestoneType.goalReached));
      expect(MilestoneType.values, contains(MilestoneType.healthyBmi));
      expect(MilestoneType.values, contains(MilestoneType.earlyBird));
      expect(MilestoneType.values, contains(MilestoneType.nightOwl));
      expect(MilestoneType.values, contains(MilestoneType.newYear));
      expect(MilestoneType.values, contains(MilestoneType.yearEnd));
      expect(MilestoneType.values, contains(MilestoneType.weekendWarrior));
    });

    test('MilestoneType category mapping assigns correct categories', () {
      expect(MilestoneType.firstEntry.category, MilestoneCategory.goals);
      expect(MilestoneType.streak7.category, MilestoneCategory.streaks);
      expect(MilestoneType.earlyBird.category, MilestoneCategory.routines);
      expect(MilestoneType.newYear.category, MilestoneCategory.special);
    });
  });
}
