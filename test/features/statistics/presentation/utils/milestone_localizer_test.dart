import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('MilestoneTypeLocalizer', () {
    test('localizedTitle returns non-empty string for all milestone types', () {
      for (final type in MilestoneType.values) {
        final title = type.localizedTitle(l10n);
        expect(title, isNotEmpty);
      }
    });

    test(
      'localizedDescription returns non-empty string for all milestone types',
      () {
        for (final type in MilestoneType.values) {
          final desc = type.localizedDescription(l10n);
          expect(desc, isNotEmpty);
        }
      },
    );

    test('sample milestone mappings return expected localized values', () {
      expect(
        MilestoneType.firstEntry.localizedTitle(l10n),
        l10n.milestoneFirstEntryTitle,
      );
      expect(
        MilestoneType.firstEntry.localizedDescription(l10n),
        l10n.milestoneFirstEntryDesc,
      );
      expect(
        MilestoneType.streak7.localizedTitle(l10n),
        l10n.milestoneStreak7Title,
      );
      expect(
        MilestoneType.goalReached.localizedTitle(l10n),
        l10n.milestoneGoalReachedTitle,
      );
      expect(
        MilestoneType.healthyBmi.localizedTitle(l10n),
        l10n.milestoneHealthyBmiTitle,
      );
    });
  });

  group('MilestoneCategoryLocalizer', () {
    test(
      'localizedName returns expected localized title for each category',
      () {
        expect(
          MilestoneCategory.goals.localizedName(l10n),
          l10n.categoryMilestones,
        );
        expect(
          MilestoneCategory.streaks.localizedName(l10n),
          l10n.categoryStreaks,
        );
        expect(
          MilestoneCategory.routines.localizedName(l10n),
          l10n.categoryRoutines,
        );
        expect(
          MilestoneCategory.special.localizedName(l10n),
          l10n.categorySpecial,
        );
      },
    );

    test('all category names are unique and non-empty', () {
      final names = MilestoneCategory.values
          .map((c) => c.localizedName(l10n))
          .toSet();
      expect(names.length, MilestoneCategory.values.length);
      for (final name in names) {
        expect(name.isNotEmpty, isTrue);
      }
    });
  });
}
