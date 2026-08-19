import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying a progress spinner during CSV parsing.
class CsvImportLoadingView extends StatelessWidget {
  /// Creates a [CsvImportLoadingView] widget.
  const CsvImportLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16.0),
          Text(
            l10n.csvImportLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
