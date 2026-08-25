import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';
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
          message: 'Could not open email client for contact@ekerstudio.com',
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
          message: 'Could not open email client for contact@ekerstudio.com',
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
    final isPolish = l10n.localeName.startsWith('pl');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy), centerTitle: false),
      body: SafeArea(
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
                            color: colorScheme.primary.withValues(alpha: 0.15),
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
                                isPolish
                                    ? 'Polityka prywatności (100% Local-First)'
                                    : 'Privacy Policy (100% Local-First)',
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
                      isPolish
                          ? 'Data wejścia w życie: 20 sierpnia 2026\nEKER Studio stworzyło aplikację Balance jako wolne od reklam narzędzie dbające o pełną prywatność Twoich danych.'
                          : 'Effective date: August 20, 2026\nEKER Studio built the Balance app as an ad-free utility respecting your complete data privacy.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _PrivacySectionCard(
              icon: Icons.sd_storage_outlined,
              title: isPolish
                  ? '1. Przechowywanie danych i pomiarów'
                  : '1. Information Collection & Storage',
              body: isPolish
                  ? '• Pomiary zdrowotne: Wszystkie wpisy wagi, wzrost, obliczenia BMI, waga docelowa i notatki w kalendarzu są przechowywane WYŁĄCZNIE LOKALNIE w pamięci Twojego urządzenia. Nie utrzymujemy zewnętrznych serwerów gromadzących Twoje pomiary.\n• Bezpieczeństwo biometryczne: Jeśli włączysz blokadę aplikacji (odcisk palca / Face ID), autoryzacja jest w całości procesowana przez system operacyjny Twojego telefonu. Aplikacja nie przetwarza ani nie zapisuje danych biometrycznych.'
                  : '• Personal & Health Data: All metrics (weight entries, height, BMI calculations, target goals, calendar logs) are stored EXCLUSIVELY LOCALLY on your device. We do not operate external servers collecting health data.\n• Biometric Security: If biometric lock is enabled (Fingerprint/FaceID), authentication is handled entirely by your device operating system.',
            ),
            const SizedBox(height: 12),

            _PrivacySectionCard(
              icon: Icons.sync_outlined,
              title: isPolish
                  ? '2. Integracja z Google Health Connect'
                  : '2. Google Health Connect Integration',
              body: isPolish
                  ? '• Aplikacja Balance łączy się z Google Health Connect wyłącznie po udzieleniu przez Ciebie wyraźnej zgody.\n• Dane są wykorzystywane ściśle do prezentacji pomiarów w aplikacji.\n• Nigdy nie sprzedajemy ani nie przekazujemy danych z Health Connect podmiotom trzecim, reklamodawcom ani brokerom danych.'
                  : '• Balance connects with Google Health Connect only after explicit user permission.\n• Data is used strictly to display metrics within the app.\n• We never sell or share Health Connect data with third parties, advertisers, or data brokers.',
            ),
            const SizedBox(height: 12),

            _PrivacySectionCard(
              icon: Icons.bug_report_outlined,
              title: isPolish
                  ? '3. Raportowanie błędów i diagnostyka'
                  : '3. Crash Reporting & Diagnostics',
              body: isPolish
                  ? '• Aplikacja może gromadzić anonimowe, techniczne logi awarii za pośrednictwem Firebase Crashlytics w celu diagnozowania usterek i poprawy stabilności.\n• Raporty nie zawierają wpisów wagi, wzrostu ani żadnych danych osobowych.'
                  : '• The app may collect anonymous technical crash logs via Firebase Crashlytics to diagnose defects and improve stability.\n• Logs do not contain personal health entries or identifiable sensitive data.',
            ),
            const SizedBox(height: 12),

            _PrivacySectionCard(
              icon: Icons.lock_outline,
              title: isPolish
                  ? '4. Dostęp stron trzecich i kopie'
                  : '4. Third-Party Access & Sharing',
              body: isPolish
                  ? '• Nie sprzedajemy, nie handlujemy ani nie udostępniamy Twoich danych osobowych.\n• Wszelkie kopie zapasowe (eksport CSV) są generowane lokalnie i pozostają pod Twoją pełną kontrolą.'
                  : '• We do not sell, trade, rent, or share personal data with third parties.\n• All backups (e.g. CSV exports) are generated locally under your full control.',
            ),
            const SizedBox(height: 12),

            _PrivacySectionCard(
              icon: Icons.health_and_safety_outlined,
              title: isPolish
                  ? '5. Zastrzeżenie medyczne'
                  : '5. Medical Disclaimer',
              body: isPolish
                  ? '• Aplikacja Balance ma charakter pomocniczy i informacyjny. Nie jest wyrobem medycznym i nie służy do diagnozowania, leczenia ani zapobiegania chorobom.'
                  : '• Balance is intended for personal tracking and informational purposes only. It is not a medical device and does not diagnose or treat any medical condition.',
            ),
            const SizedBox(height: 12),

            _PrivacySectionCard(
              icon: Icons.family_restroom_outlined,
              title: isPolish
                  ? '6. Prywatność dzieci'
                  : '6. Children\'s Privacy',
              body: isPolish
                  ? '• Aplikacja nie jest skierowana do dzieci poniżej 13 roku życia. Nie zbieramy świadomie danych od dzieci.'
                  : '• Our app is not directed to children under 13. We do not knowingly collect personal data from children.',
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
                          isPolish ? '7. Kontakt z nami' : '7. Contact Us',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPolish
                          ? 'W przypadku pytań lub uwag dotyczących niniejszej Polityki Prywatności, skontaktuj się z nami:'
                          : 'If you have any questions or suggestions regarding this Privacy Policy, please contact us:',
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
