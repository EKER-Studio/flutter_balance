import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'custom_settings_tile.dart';

/// Data settings group with CSV import, export, and wipe controls.
class DataSection extends StatelessWidget {
  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the import tile is tapped.
  final VoidCallback onImportTap;

  /// Callback invoked when the export tile is tapped.
  final VoidCallback onExportTap;

  /// Callback invoked when the wipe data tile is tapped.
  final VoidCallback onWipeTap;

  /// Creates a [DataSection] with the given dependencies.
  const DataSection({super.key, 
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          CustomSettingsTile(
            icon: Icons.file_upload_outlined,
            title: l10n.importCsv,
            sectionLabel: l10n.dataSection,
            onTap: onImportTap,
          ),
          CustomSettingsTile(
            icon: Icons.file_download_outlined,
            title: l10n.exportCsv,
            sectionLabel: l10n.dataSection,
            onTap: onExportTap,
          ),
          CustomSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.wipeData,
            isError: true,
            showChevron: false,
            sectionLabel: l10n.dataSection,
            onTap: onWipeTap,
          ),
        ],
      ),
    );
  }
}
