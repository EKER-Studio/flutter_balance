import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'custom_settings_tile.dart';

/// Help settings group with the crash log sharing and app version tiles.
class HelpSection extends StatefulWidget {
  /// Localized strings for this section.
  final AppLocalizations l10n;

  /// Callback invoked when the send crash log tile is tapped.
  final VoidCallback onCrashLogTap;

  /// Creates a [HelpSection] with the given dependencies.
  const HelpSection({super.key, required this.l10n, required this.onCrashLogTap});

  @override
  State<HelpSection> createState() => HelpSectionState();
}

class HelpSectionState extends State<HelpSection> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '';
          return Column(
            children: [
              CustomSettingsTile(
                icon: Icons.bug_report_outlined,
                title: l10n.sendCrashLog,
                sectionLabel: l10n.helpSection,
                onTap: widget.onCrashLogTap,
              ),
              CustomSettingsTile(
                icon: Icons.info_outline,
                title: l10n.appVersion,
                subtitle: version,
                showChevron: false,
                sectionLabel: l10n.helpSection,
              ),
            ],
          );
        },
      ),
    );
  }
}
