// Dialog confirming the complete wipe of all app data.

import 'package:flutter/material.dart';
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final isLandscapePhone =
        MediaQuery.of(context).orientation == Orientation.landscape &&
        MediaQuery.sizeOf(context).height < 500;

    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscapePhone ? 32 : 24,
        vertical: isLandscapePhone ? 8 : 24,
      ),
      icon: isLandscapePhone
          ? null
          : Icon(Icons.delete_forever_outlined, size: 28, color: errorColor),
      title: Text(l10n.wipeData),
      contentPadding: EdgeInsets.fromLTRB(
        24,
        isLandscapePhone ? 8 : 16,
        24,
        isLandscapePhone ? 12 : 20,
      ),
      content: SizedBox(width: 320, child: Text(l10n.wipeDataContent)),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: errorColor,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(l10n.wipeDataButton),
        ),
      ],
    );
  }
}
