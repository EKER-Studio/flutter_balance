import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_tile.dart';

/// A widget that displays the help settings group with BMI categories, privacy policy, open source licenses, and app version tiles.
class HelpSection extends StatefulWidget {
  final AppLocalizations l10n;
  final VoidCallback onBmiCategoriesTap;
  final VoidCallback onPrivacyPolicyTap;
  final VoidCallback onLicensesTap;

  const HelpSection({
    super.key,
    required this.l10n,
    required this.onBmiCategoriesTap,
    required this.onPrivacyPolicyTap,
    required this.onLicensesTap,
  });

  @override
  State<HelpSection> createState() => HelpSectionState();
}

/// State for [HelpSection] loading and displaying application package metadata.
class HelpSectionState extends State<HelpSection> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _openGitHub(BuildContext context) async {
    AppAnalytics.logSettingsViewOnGitHubClicked();
    final uri = Uri.parse('https://github.com/EKER-Studio/flutter_balance');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackBar.show(
          context,
          message:
              'Could not open https://github.com/EKER-Studio/flutter_balance',
        );
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to launch GitHub repository URL',
        fatal: false,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message:
              'Could not open https://github.com/EKER-Studio/flutter_balance',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '';
          return Column(
            children: [
              CustomSettingsTile(
                icon: Icons.monitor_weight_outlined,
                title: l10n.bmiLegendTitle,
                sectionLabel: l10n.helpSection,
                onTap: widget.onBmiCategoriesTap,
              ),
              CustomSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                sectionLabel: l10n.helpSection,
                onTap: widget.onPrivacyPolicyTap,
              ),
              CustomSettingsTile(
                icon: Icons.article_outlined,
                title: l10n.openSourceLicenses,
                sectionLabel: l10n.helpSection,
                onTap: widget.onLicensesTap,
              ),
              CustomSettingsTile(
                icon: Icons.code_rounded,
                title: l10n.viewOnGitHub,
                sectionLabel: l10n.helpSection,
                onTap: () => _openGitHub(context),
              ),
              CustomSettingsTile(
                icon: Icons.info_outline,
                title: l10n.appVersion,
                subtitle: version,
                showChevron: false,
                sectionLabel: l10n.helpSection,
                onTap: () {
                  AppAnalytics.logSettingsAppVersionTapped(version);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
