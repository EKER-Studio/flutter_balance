// Error state shown when the local weight database cannot be read.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Error state for failed local database reads, with a retry action that
/// dispatches [RefreshWeightData].
class CalendarErrorCard extends StatelessWidget {
  /// The error message returned by the [WeightBloc]; a default message is
  /// shown when empty.
  final String errorMessage;

  const CalendarErrorCard({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: cs.onErrorContainer.withValues(alpha: 0.15),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: cs.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.databaseErrorTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.isNotEmpty
                  ? errorMessage
                  : l10n.databaseErrorDefaultMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<WeightBloc>().add(const RefreshWeightData());
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: FilledButton.styleFrom(
                backgroundColor: cs.onErrorContainer,
                foregroundColor: cs.errorContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
