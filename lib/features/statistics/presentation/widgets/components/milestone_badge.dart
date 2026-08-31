import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// An interactive badge displaying an individual milestone achievement.
class MilestoneBadge extends StatelessWidget {
  /// The milestone represented by this badge.
  final Milestone milestone;

  const MilestoneBadge({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = milestone.type.localizedTitle(l10n);
    final description = milestone.type.localizedDescription(l10n);
    final isUnlocked = milestone.isUnlocked;

    return Semantics(
      button: true,
      label: '$title: ${isUnlocked ? "Odblokowane" : "Zablokowane"}',
      child: InkWell(
        onTap: () {
          AppAnalytics.logStatisticsMilestoneDetailTapped(
            milestoneType: milestone.type.name,
            isUnlocked: isUnlocked,
          );
          _showDetailDialog(context, l10n, cs, title, description);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isUnlocked
                ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                : cs.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? cs.primary.withValues(alpha: 0.25)
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      milestone.icon,
                      size: 22,
                      color: isUnlocked
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: isUnlocked ? cs.primary : cs.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnlocked ? Icons.check : Icons.lock_outline,
                        size: 10,
                        color: isUnlocked ? cs.onPrimary : cs.surface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w500,
                    color: isUnlocked ? cs.onSurface : cs.onSurfaceVariant,
                    fontSize: 10.5,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (!isUnlocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    height: 3,
                    width: double.infinity,
                    color: cs.surfaceContainerHighest,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: milestone.progress.clamp(0.0, 1.0),
                      child: Container(color: cs.secondary),
                    ),
                  ),
                )
              else
                Container(
                  height: 3,
                  width: 18,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    String title,
    String description,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: milestone.isUnlocked
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            milestone.icon,
            size: 28,
            color: milestone.isUnlocked
                ? cs.primary
                : cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(
                ctx,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (milestone.isUnlocked && milestone.unlockedDate != null)
              Text(
                DateFormat.yMMMMd(
                  l10n.localeName,
                ).format(milestone.unlockedDate!),
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (!milestone.isUnlocked)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: milestone.progress.clamp(0.0, 1.0),
                        child: Container(color: cs.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(milestone.progress * 100).toInt()}%',
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
