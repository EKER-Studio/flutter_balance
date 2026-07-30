import 'package:flutter/material.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Reusable Material 3 informational card displayed when a user selects a future date.
class CalendarDayFutureCard extends StatelessWidget {
  /// The selected future date.
  final DateTime selectedDate;

  /// Callback when the user taps to return selection to today.
  final VoidCallback onSelectToday;

  /// Creates a [CalendarDayFutureCard].
  const CalendarDayFutureCard({
    super.key,
    required this.selectedDate,
    required this.onSelectToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: cs.secondaryContainer,
              child: Icon(
                Icons.schedule,
                size: 40,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.futureDateTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.futureDateSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSelectToday,
              icon: const Icon(Icons.today),
              label: Text(l10n.goToToday),
            ),
          ],
        ),
      ),
    );
  }
}
