import 'package:flutter/material.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying error details and a retry button for failed CSV import.
class CsvImportErrorView extends StatelessWidget {
  /// The localized error message to present.
  final String message;
  final VoidCallback onRetry;
  final bool isLandscape;

  const CsvImportErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return OnboardingStepLayout(
      title: l10n.csvImportStepTitle,
      subtitle: l10n.csvImportStepSubtitle,
      content: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0)),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 16.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
      footer: FilledButton(
        key: const Key('csv_import_retry_button'),
        onPressed: onRetry,
        child: Text(l10n.retry),
      ),
    );
  }
}
