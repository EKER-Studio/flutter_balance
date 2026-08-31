import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Extension providing localized strings for [MilestoneType].
extension MilestoneTypeLocalizer on MilestoneType {
  /// Returns the localized title of the milestone.
  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      case MilestoneType.firstEntry:
        return l10n.milestoneFirstEntryTitle;
      case MilestoneType.streak7:
        return l10n.milestoneStreak7Title;
      case MilestoneType.streak30:
        return l10n.milestoneStreak30Title;
      case MilestoneType.streak100:
        return l10n.milestoneStreak100Title;
      case MilestoneType.weightLoss1kg:
        return l10n.milestoneLoss1Title;
      case MilestoneType.weightLoss5kg:
        return l10n.milestoneLoss5Title;
      case MilestoneType.weightLoss10kg:
        return l10n.milestoneLoss10Title;
      case MilestoneType.weightGain1kg:
        return l10n.weightGain1kgTitle;
      case MilestoneType.weightGain5kg:
        return l10n.weightGain5kgTitle;
      case MilestoneType.weightGain10kg:
        return l10n.weightGain10kgTitle;
      case MilestoneType.goalHalfway:
        return l10n.milestoneGoalHalfwayTitle;
      case MilestoneType.goalReached:
        return l10n.milestoneGoalReachedTitle;
      case MilestoneType.healthyBmi:
        return l10n.milestoneHealthyBmiTitle;
    }
  }

  /// Returns the localized description of the milestone.
  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case MilestoneType.firstEntry:
        return l10n.milestoneFirstEntryDesc;
      case MilestoneType.streak7:
        return l10n.milestoneStreak7Desc;
      case MilestoneType.streak30:
        return l10n.milestoneStreak30Desc;
      case MilestoneType.streak100:
        return l10n.milestoneStreak100Desc;
      case MilestoneType.weightLoss1kg:
        return l10n.milestoneLoss1Desc;
      case MilestoneType.weightLoss5kg:
        return l10n.milestoneLoss5Desc;
      case MilestoneType.weightLoss10kg:
        return l10n.milestoneLoss10Desc;
      case MilestoneType.weightGain1kg:
        return l10n.weightGain1kgDesc;
      case MilestoneType.weightGain5kg:
        return l10n.weightGain5kgDesc;
      case MilestoneType.weightGain10kg:
        return l10n.weightGain10kgDesc;
      case MilestoneType.goalHalfway:
        return l10n.milestoneGoalHalfwayDesc;
      case MilestoneType.goalReached:
        return l10n.milestoneGoalReachedDesc;
      case MilestoneType.healthyBmi:
        return l10n.milestoneHealthyBmiDesc;
    }
  }
}
