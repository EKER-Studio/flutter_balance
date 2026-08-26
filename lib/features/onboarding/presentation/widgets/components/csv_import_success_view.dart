import 'package:flutter/material.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying the success state and count of imported entries.
class CsvImportSuccessView extends StatelessWidget {
  final int count;
  final VoidCallback onContinue;
  final bool isLandscape;

  const CsvImportSuccessView({
    super.key,
    required this.count,
    required this.onContinue,
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
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.file_upload_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              l10n.csvImportSuccess(count),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.csvImportSuccessSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      footer: FilledButton(
        key: const Key('csv_import_continue_button'),
        onPressed: onContinue,
        child: Text(l10n.next),
      ),
    );
  }
}
