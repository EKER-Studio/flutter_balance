import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Coordinates milestone evaluations and triggers system notifications when new achievements are unlocked.
class MilestoneNotificationCoordinator {
  Set<MilestoneType>? _knownUnlockedTypes;

  /// Visible for testing to check current tracked unlocked types.
  Set<MilestoneType>? get knownUnlockedTypes => _knownUnlockedTypes;

  /// Checks for newly unlocked achievements and fires notifications if any are detected.
  ///
  /// On the initial invocation for a session, baseline unlocked milestones are established
  /// without triggering historical notifications. Subsequent invocations compare newly
  /// unlocked achievements against the baseline and notify the user.
  void checkForNewMilestones({
    required List<WeightEntry> entries,
    double? targetWeight,
    double? heightCm,
    WeightGoalMode goalMode = WeightGoalMode.lose,
    required AppLocalizations l10n,
    NotificationService? notificationService,
  }) {
    if (entries.isEmpty) return;

    final currentMilestones = MilestoneCalculator.evaluate(
      entries: entries,
      targetWeight: targetWeight,
      heightCm: heightCm,
      goalMode: goalMode,
    );

    if (_knownUnlockedTypes == null) {
      _knownUnlockedTypes = currentMilestones
          .where((m) => m.isUnlocked)
          .map((m) => m.type)
          .toSet();
      return;
    }

    final newlyUnlocked = currentMilestones
        .where((m) => m.isUnlocked && !_knownUnlockedTypes!.contains(m.type))
        .toList();

    if (newlyUnlocked.isEmpty) return;

    for (final milestone in newlyUnlocked) {
      _knownUnlockedTypes!.add(milestone.type);
    }

    final service = notificationService ?? NotificationService.instance;

    if (newlyUnlocked.length > 2) {
      service.showMultipleAchievementsNotification(
        count: newlyUnlocked.length,
        title: l10n.multipleAchievementsUnlockedNotificationTitle,
        body: l10n.multipleAchievementsUnlockedNotificationBody(
          newlyUnlocked.length,
        ),
      );
    } else {
      for (final milestone in newlyUnlocked) {
        final title = l10n.achievementUnlockedNotificationTitle;
        final badgeName = milestone.type.localizedTitle(l10n);
        final badgeDesc = milestone.type.localizedDescription(l10n);
        final body = '$badgeName — $badgeDesc';

        service.showAchievementNotification(
          id: milestone.type.index + 100,
          title: title,
          body: body,
        );
      }
    }
  }

  /// Resets the tracked baseline (e.g. when database entries are cleared).
  void reset() {
    _knownUnlockedTypes = null;
  }
}
