import 'package:flutter/material.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog prompting the user to install Google Health Connect from Google Play.
class HealthConnectInstallDialog extends StatelessWidget {
  /// Creates a [HealthConnectInstallDialog] widget.
  const HealthConnectInstallDialog({super.key});

  /// Shows the dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const HealthConnectInstallDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(l10n.healthConnectRequiredTitle),
      content: SizedBox(
        width: 320,
        child: Text(l10n.healthConnectRequiredSubtitle),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            NativeHealthService.instance.installHealthConnect();
          },
          child: Text(l10n.installFromPlayStore),
        ),
      ],
    );
  }
}
