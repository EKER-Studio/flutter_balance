// Dialog confirming the complete wipe of all app data.

import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A modal dialog confirming the irreversible deletion of all database records.
class WipeDataDialog extends StatelessWidget {
  const WipeDataDialog({super.key});

  /// Displays the dialog and returns `true` if the wipe was confirmed,
  /// or `false` when cancelled/dismissed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const WipeDataDialog(),
    );
    final confirmed = result ?? false;
    if (!confirmed) {
      AppAnalytics.logSettingsWipeDialogCancelled();
    }
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(l10n.wipeData),
      content: SizedBox(width: 320, child: Text(l10n.wipeDataContent)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: Text(l10n.wipeDataButton),
        ),
      ],
    );
  }
}
