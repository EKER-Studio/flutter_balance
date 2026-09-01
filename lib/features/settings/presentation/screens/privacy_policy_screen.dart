import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A native, offline-accessible screen displaying the application Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _sendContactEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contact@ekerstudio.com',
      queryParameters: {'subject': 'Balance App — Privacy Policy Inquiry'},
    );
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(
            context,
          ).couldNotOpenEmailClient('contact@ekerstudio.com'),
        );
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to launch privacy policy email client',
        fatal: false,
      );
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(
            context,
          ).couldNotOpenEmailClient('contact@ekerstudio.com'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy), centerTitle: false),
      body: SafeArea(
        child: ClampedLayout(
          maxWidth: AppLayoutTokens.maxSingleColumnContentWidth,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balance',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.privacyPolicyHeaderSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.privacyPolicyIntro,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _PrivacySectionCard(
                icon: Icons.storage_outlined,
                title: l10n.privacyPolicySection1Title,
                body: l10n.privacyPolicySection1Body,
              ),
              const SizedBox(height: 12),

              _PrivacySectionCard(
                icon: Icons.sync_outlined,
                title: l10n.privacyPolicySection2Title,
                body: l10n.privacyPolicySection2Body,
              ),
              const SizedBox(height: 12),

              _PrivacySectionCard(
                icon: Icons.bug_report_outlined,
                title: l10n.privacyPolicySection3Title,
                body: l10n.privacyPolicySection3Body,
              ),
              const SizedBox(height: 12),

              _PrivacySectionCard(
                icon: Icons.lock_outline,
                title: l10n.privacyPolicySection4Title,
                body: l10n.privacyPolicySection4Body,
              ),
              const SizedBox(height: 12),

              _PrivacySectionCard(
                icon: Icons.health_and_safety_outlined,
                title: l10n.privacyPolicySection5Title,
                body: l10n.privacyPolicySection5Body,
              ),
              const SizedBox(height: 12),

              _PrivacySectionCard(
                icon: Icons.family_restroom_outlined,
                title: l10n.privacyPolicySection6Title,
                body: l10n.privacyPolicySection6Body,
              ),
              const SizedBox(height: 12),

              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.privacyPolicySection7Title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.privacyPolicySection7Body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _sendContactEmail(context),
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: const Text('contact@ekerstudio.com'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacySectionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
