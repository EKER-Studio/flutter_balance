import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestone_badge.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A modal bottom sheet displaying the complete achievements gallery grouped by category.
class MilestonesGallerySheet extends StatelessWidget {
  /// The list of evaluated milestones.
  final List<Milestone> milestones;

  const MilestonesGallerySheet({super.key, required this.milestones});

  /// Displays the milestones gallery bottom sheet.
  static Future<void> show(
    BuildContext context,
    List<Milestone> milestones,
  ) async {
    AppAnalytics.logEvent(name: 'achievements_gallery_opened');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MilestonesGallerySheet(milestones: milestones),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final unlockedCount = milestones.where((m) => m.isUnlocked).length;
    final totalCount = milestones.length;

    const categories = [
      MilestoneCategory.goals,
      MilestoneCategory.streaks,
      MilestoneCategory.routines,
      MilestoneCategory.special,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.military_tech_outlined,
                      size: 26,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.achievementsGalleryTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.milestonesUnlocked(unlockedCount, totalCount),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryMilestones = milestones
                        .where((m) => m.type.category == category)
                        .toList();

                    if (categoryMilestones.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final catUnlocked = categoryMilestones
                        .where((m) => m.isUnlocked)
                        .length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.localizedName(l10n),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '$catUnlocked / ${categoryMilestones.length}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final milestone in categoryMilestones)
                                MilestoneBadge(milestone: milestone),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
