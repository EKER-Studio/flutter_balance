import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Welcome/landing step displayed as the very first screen of the onboarding
/// wizard. Sets user expectations and resolves initial keyboard focus issues
///// by deferring input fields until after an explicit user gesture.
class StepWelcome extends StatelessWidget {
  /// Callback invoked when the user proceeds to the next step.
  final VoidCallback onNext;

  /// Creates a [StepWelcome] widget.
  const StepWelcome({super.key, required this.onNext});

  /// Builds a single feature highlight card with an emoji icon, a title, and
  /// an optional description.
  Widget _buildFeatureCard(
    BuildContext context, {
    required String emoji,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32.0),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40.0),
          _buildFeatureCard(
            context,
            emoji: '\u{1F4CF}',
            title: l10n.onboardingWelcomeUnitsHeight,
          ),
          const SizedBox(height: 12.0),
          _buildFeatureCard(
            context,
            emoji: '\u{1F3AF}',
            title: l10n.onboardingWelcomeTargetWeight,
          ),
          const SizedBox(height: 12.0),
          _buildFeatureCard(
            context,
            emoji: '\u{1F512}',
            title: l10n.onboardingWelcomePrivacy,
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: FilledButton(
              key: const Key('welcome_step_start_button'),
              onPressed: onNext,
              child: Text(l10n.onboardingWelcomeStart),
            ),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
