import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'custom_settings_tile.dart';

/// A widget that displays the data settings group with CSV import, export, and wipe controls.
class DataSection extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onImportTap;
  final VoidCallback onExportTap;
  final VoidCallback onWipeTap;

  const DataSection({
    super.key,
    required this.l10n,
    required this.onImportTap,
    required this.onExportTap,
    required this.onWipeTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.file_upload_outlined,
            title: l10n.importCsv,
            sectionLabel: l10n.dataSection,
            onTap: () {
              AppAnalytics.logSettingsCsvImportClicked();
              onImportTap();
            },
          ),
          CustomSettingsTile(
            icon: Icons.file_download_outlined,
            title: l10n.exportCsv,
            sectionLabel: l10n.dataSection,
            onTap: () {
              AppAnalytics.logSettingsCsvExportClicked();
              onExportTap();
            },
          ),
          CustomSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.wipeData,
            isError: true,
            showChevron: false,
            sectionLabel: l10n.dataSection,
            onTap: () {
              AppAnalytics.logSettingsWipeTileClicked();
              onWipeTap();
            },
          ),
        ],
      ),
    );
  }
}
