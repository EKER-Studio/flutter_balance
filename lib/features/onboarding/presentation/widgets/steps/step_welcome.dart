import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Welcome/landing step displayed as the very first screen of the onboarding
/// wizard. Sets user expectations and resolves initial keyboard focus issues
/// by deferring input fields until after an explicit user gesture.
class StepWelcome extends StatelessWidget {
  /// Callback invoked when the user proceeds to the next step.
  final VoidCallback onNext;

  /// Creates a [StepWelcome] widget.
  const StepWelcome({super.key, required this.onNext});

  /// Builds a single feature highlight card with an icon, a title, and
  /// an optional description.
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isLandscape = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isLandscape ? 10.0 : 12.0,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isLandscape ? 6.0 : 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child: Icon(
                icon,
                size: isLandscape ? 18.0 : 20.0,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style:
                    (isLandscape
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final featureCards = [
      _buildFeatureCard(
        context,
        icon: Icons.straighten,
        title: l10n.onboardingWelcomeUnitsHeight,
        isLandscape: isLandscape,
      ),
      _buildFeatureCard(
        context,
        icon: Icons.monitor_weight_outlined,
        title: l10n.onboardingWelcomeInitialWeight,
        isLandscape: isLandscape,
      ),
      _buildFeatureCard(
        context,
        icon: Icons.track_changes,
        title: l10n.onboardingWelcomeTargetWeight,
        isLandscape: isLandscape,
      ),
      _buildFeatureCard(
        context,
        icon: Icons.monitor_heart_outlined,
        title: l10n.onboardingWelcomeHealthSync,
        isLandscape: isLandscape,
      ),
      _buildFeatureCard(
        context,
        icon: Icons.notifications_outlined,
        title: l10n.onboardingWelcomeDailyReminders,
        isLandscape: isLandscape,
      ),
      _buildFeatureCard(
        context,
        icon: Icons.lock_outline,
        title: l10n.onboardingWelcomePrivacy,
        isLandscape: isLandscape,
      ),
    ];

    return ClampedLayout(
      padding: EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: isLandscape ? 12.0 : 24.0,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: isLandscape ? 4.0 : 16.0),
            Text(
              l10n.onboardingWelcomeTitle,
              style:
                  (isLandscape
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.headlineMedium)
                      ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              l10n.onboardingWelcomeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 12.0 : 24.0),
            if (isLandscape) ...[
              Row(
                children: [
                  Expanded(child: featureCards[0]),
                  const SizedBox(width: 8.0),
                  Expanded(child: featureCards[1]),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(child: featureCards[2]),
                  const SizedBox(width: 8.0),
                  Expanded(child: featureCards[3]),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(child: featureCards[4]),
                  const SizedBox(width: 8.0),
                  Expanded(child: featureCards[5]),
                ],
              ),
            ] else ...[
              for (int i = 0; i < featureCards.length; i++) ...[
                featureCards[i],
                if (i < featureCards.length - 1) const SizedBox(height: 12.0),
              ],
            ],
            SizedBox(height: isLandscape ? 16.0 : 24.0),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48.0),
              child: FilledButton(
                key: const Key('welcome_step_start_button'),
                onPressed: onNext,
                child: Text(l10n.onboardingWelcomeStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
