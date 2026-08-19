import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget that displays a hint about inexact alarm scheduling.
///
/// This hint is shown when the exact alarm permission was revoked.
class InexactReminderHint extends StatelessWidget {
  /// The localized strings for the hint.
  final AppLocalizations l10n;

  /// Creates an [InexactReminderHint] with the given [l10n].
  const InexactReminderHint({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          AppAnalytics.logSettingsInexactNotificationHintTapped();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.notificationInexactHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
