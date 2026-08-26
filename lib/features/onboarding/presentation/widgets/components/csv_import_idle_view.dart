import 'package:flutter/material.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying the idle state of the CSV import step.
class CsvImportIdleView extends StatelessWidget {
  final VoidCallback onPickFile;
  final VoidCallback onSkipped;
  final bool isLandscape;

  const CsvImportIdleView({
    super.key,
    required this.onPickFile,
    required this.onSkipped,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return OnboardingStepLayout(
      title: l10n.csvImportStepTitle,
      subtitle: l10n.csvImportStepSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16.0),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: InkWell(
                key: const Key('csv_import_tile'),
                onTap: onPickFile,
                child: ListTile(
                  leading: ExcludeSemantics(
                    child: Icon(
                      Icons.upload_file,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    l10n.csvImportTileTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    l10n.csvImportTileSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const ExcludeSemantics(
                    child: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: isLandscape ? 6.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.csvFormatHintTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: isLandscape ? 4.0 : 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    l10n.csvFormatHintExample,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: FilledButton(
        key: const Key('csv_import_next_button'),
        onPressed: onSkipped,
        child: Text(l10n.next),
      ),
    );
  }
}
