import 'package:flutter/material.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog prompting the user to install Google Health Connect from Google Play.
class HealthConnectInstallDialog extends StatelessWidget {
  /// Creates a [HealthConnectInstallDialog] widget.
  const HealthConnectInstallDialog({super.key, this.onStoreClicked});

  /// Shows the dialog.
  static Future<void> show(BuildContext context) async {
    AppAnalytics.logSettingsHealthConnectInstallDialogOpened();
    bool storeClicked = false;
    await showDialog<void>(
      context: context,
      builder: (_) =>
          HealthConnectInstallDialog(onStoreClicked: () => storeClicked = true),
    );
    if (!storeClicked) {
      AppAnalytics.logSettingsHealthConnectInstallDialogCancelled();
    }
  }

  /// Optional callback invoked when the user selects the store action.
  final VoidCallback? onStoreClicked;

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
            onStoreClicked?.call();
            AppAnalytics.logSettingsHealthConnectInstallDialogStoreClicked();
            Navigator.pop(context);
            NativeHealthService.instance.installHealthConnect();
          },
          child: Text(l10n.installFromPlayStore),
        ),
      ],
    );
  }
}
