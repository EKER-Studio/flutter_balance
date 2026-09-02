import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('MilestoneCalculator', () {
    test('returns all milestones locked when entries is empty', () {
      final milestones = MilestoneCalculator.evaluate(
        entries: [],
        targetWeight: 70,
        heightCm: 175,
      );

      expect(milestones.length, greaterThanOrEqualTo(8));
      expect(milestones.every((m) => !m.isUnlocked), isTrue);
      expect(milestones.every((m) => m.progress == 0.0), isTrue);
    });

    test('unlocks firstEntry milestone with single entry', () {
      final milestones = MilestoneCalculator.evaluate(
        entries: [
          WeightEntry(id: 1, weightKg: 85.0, dateTime: DateTime(2026, 8, 1)),
        ],
      );

      final firstEntryMilestone = milestones.firstWhere(
        (m) => m.type == MilestoneType.firstEntry,
      );
      expect(firstEntryMilestone.isUnlocked, isTrue);
      expect(firstEntryMilestone.progress, 1.0);
      expect(firstEntryMilestone.unlockedDate, DateTime(2026, 8, 1));
    });

    test('evaluates streak milestones correctly', () {
      final baseDate = DateTime(2026, 8, 1);
      final entries = List.generate(
        8,
        (i) => WeightEntry(
          id: i + 1,
          weightKg: 80.0,
          dateTime: baseDate.add(Duration(days: i)),
        ),
      );

      final milestones = MilestoneCalculator.evaluate(entries: entries);

      final streak7 = milestones.firstWhere(
        (m) => m.type == MilestoneType.streak7,
      );
      final streak30 = milestones.firstWhere(
        (m) => m.type == MilestoneType.streak30,
      );

      expect(streak7.isUnlocked, isTrue);
      expect(streak7.progress, 1.0);
      expect(streak30.isUnlocked, isFalse);
      expect(streak30.progress, closeTo(8 / 30.0, 0.01));
    });

    test('evaluates weight loss milestones correctly', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 90.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(
          id: 2,
          weightKg: 88.0,
          dateTime: DateTime(2026, 8, 5),
        ), // -2 kg
        WeightEntry(
          id: 3,
          weightKg: 84.0,
          dateTime: DateTime(2026, 8, 15),
        ), // -6 kg
      ];

      final milestones = MilestoneCalculator.evaluate(entries: entries);

      final loss1 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightLoss1kg,
      );
      final loss5 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightLoss5kg,
      );
      final loss10 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightLoss10kg,
      );

      expect(loss1.isUnlocked, isTrue);
      expect(loss5.isUnlocked, isTrue);
      expect(loss10.isUnlocked, isFalse);
      expect(loss10.progress, closeTo(6.0 / 10.0, 0.01));
    });

    test('evaluates goal milestones correctly', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 90.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(
          id: 2,
          weightKg: 84.0,
          dateTime: DateTime(2026, 8, 10),
        ), // 6 kg lost of 10 kg target (60%)
      ];

      final milestones = MilestoneCalculator.evaluate(
        entries: entries,
        targetWeight: 80.0,
      );

      final halfway = milestones.firstWhere(
        (m) => m.type == MilestoneType.goalHalfway,
      );
      final reached = milestones.firstWhere(
        (m) => m.type == MilestoneType.goalReached,
      );

      expect(halfway.isUnlocked, isTrue);
      expect(reached.isUnlocked, isFalse);
      expect(reached.progress, closeTo(0.6, 0.01));
    });

    test('evaluates healthy BMI milestone when BMI enters normal range', () {
      // Height 180cm, healthy BMI range 18.5 - 24.9 -> weight 60.0 to 80.7 kg
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 88.0,
          dateTime: DateTime(2026, 8, 1),
        ), // BMI ~ 27.16 (Overweight)
        WeightEntry(
          id: 2,
          weightKg: 78.0,
          dateTime: DateTime(2026, 8, 20),
        ), // BMI ~ 24.07 (Normal)
      ];

      final milestones = MilestoneCalculator.evaluate(
        entries: entries,
        heightCm: 180.0,
      );

      final healthyBmi = milestones.firstWhere(
        (m) => m.type == MilestoneType.healthyBmi,
      );

      expect(healthyBmi.isUnlocked, isTrue);
      expect(healthyBmi.progress, 1.0);
      expect(healthyBmi.unlockedDate, DateTime(2026, 8, 20));
    });

    test('evaluates weight gain milestones and goal in gain mode', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 70.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(
          id: 2,
          weightKg: 72.0,
          dateTime: DateTime(2026, 8, 10),
        ), // +2 kg
        WeightEntry(
          id: 3,
          weightKg: 76.0,
          dateTime: DateTime(2026, 8, 20),
        ), // +6 kg
      ];

      final milestones = MilestoneCalculator.evaluate(
        entries: entries,
        targetWeight: 80.0, // +10 kg target
        goalMode: WeightGoalMode.gain,
      );

      final gain1 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightGain1kg,
      );
      final gain5 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightGain5kg,
      );
      final gain10 = milestones.firstWhere(
        (m) => m.type == MilestoneType.weightGain10kg,
      );
      final halfway = milestones.firstWhere(
        (m) => m.type == MilestoneType.goalHalfway,
      );
      final reached = milestones.firstWhere(
        (m) => m.type == MilestoneType.goalReached,
      );

      expect(gain1.isUnlocked, isTrue);
      expect(gain5.isUnlocked, isTrue);
      expect(gain10.isUnlocked, isFalse);
      expect(gain10.progress, closeTo(6.0 / 10.0, 0.01));
      expect(halfway.isUnlocked, isTrue);
      expect(reached.isUnlocked, isFalse);
      expect(reached.progress, closeTo(0.6, 0.01));
    });

    test('evaluates early bird and night owl milestones', () {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 70.0,
          dateTime: DateTime(2026, 8, 1, 6, 30),
        ), // 6:30 AM -> early bird
        WeightEntry(
          id: 2,
          weightKg: 70.0,
          dateTime: DateTime(2026, 8, 2, 23, 15),
        ), // 11:15 PM -> night owl
      ];

      final milestones = MilestoneCalculator.evaluate(entries: entries);
      final earlyBird = milestones.firstWhere(
        (m) => m.type == MilestoneType.earlyBird,
      );
      final nightOwl = milestones.firstWhere(
        (m) => m.type == MilestoneType.nightOwl,
      );

      expect(earlyBird.isUnlocked, isTrue);
      expect(earlyBird.progress, 1.0);
      expect(nightOwl.isUnlocked, isTrue);
      expect(nightOwl.progress, 1.0);
    });

    test('evaluates special calendar milestones (New Year, Year End)', () {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 70.0,
          dateTime: DateTime(2026, 1, 1, 10, 0),
        ), // Jan 1 -> New Year
        WeightEntry(
          id: 2,
          weightKg: 70.0,
          dateTime: DateTime(2026, 12, 31, 10, 0),
        ), // Dec 31 -> Year End
      ];

      final milestones = MilestoneCalculator.evaluate(entries: entries);
      final newYear = milestones.firstWhere(
        (m) => m.type == MilestoneType.newYear,
      );
      final yearEnd = milestones.firstWhere(
        (m) => m.type == MilestoneType.yearEnd,
      );

      expect(newYear.isUnlocked, isTrue);
      expect(yearEnd.isUnlocked, isTrue);
    });

    test('evaluates comeback milestone when gap > 14 days exists', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(
          id: 2,
          weightKg: 79.5,
          dateTime: DateTime(2026, 8, 20),
        ), // 19 days gap
      ];

      final milestones = MilestoneCalculator.evaluate(entries: entries);
      final comeback = milestones.firstWhere(
        (m) => m.type == MilestoneType.comeback,
      );

      expect(comeback.isUnlocked, isTrue);
      expect(comeback.progress, 1.0);
    });

    test('evaluates weekend warrior for 4 consecutive weekends', () {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: DateTime(2026, 8, 1),
        ), // Sat (W1)
        WeightEntry(
          id: 2,
          weightKg: 80.0,
          dateTime: DateTime(2026, 8, 8),
        ), // Sat (W2)
        WeightEntry(
          id: 3,
          weightKg: 80.0,
          dateTime: DateTime(2026, 8, 16),
        ), // Sun (W3)
        WeightEntry(
          id: 4,
          weightKg: 80.0,
          dateTime: DateTime(2026, 8, 22),
        ), // Sat (W4)
      ];

      final milestones = MilestoneCalculator.evaluate(entries: entries);
      final weekendWarrior = milestones.firstWhere(
        (m) => m.type == MilestoneType.weekendWarrior,
      );

      expect(weekendWarrior.isUnlocked, isTrue);
      expect(weekendWarrior.progress, 1.0);
    });
  });
}
