import 'package:flutter/material.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/welcome_feature_card.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Welcome/landing step displayed as the very first screen of the onboarding
/// wizard. Sets user expectations and resolves initial keyboard focus issues
/// by deferring input fields until after an explicit user gesture.
class StepWelcome extends StatelessWidget {
  final VoidCallback onNext;

  const StepWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final featureCards = [
      WelcomeFeatureCard(
        icon: Icons.straighten,
        title: l10n.onboardingWelcomeUnitsHeight,
        isLandscape: isLandscape,
      ),
      WelcomeFeatureCard(
        icon: Icons.monitor_weight_outlined,
        title: l10n.onboardingWelcomeInitialWeight,
        isLandscape: isLandscape,
      ),
      WelcomeFeatureCard(
        icon: Icons.track_changes,
        title: l10n.onboardingWelcomeTargetWeight,
        isLandscape: isLandscape,
      ),
      WelcomeFeatureCard(
        icon: Icons.monitor_heart_outlined,
        title: l10n.onboardingWelcomeHealthSync,
        isLandscape: isLandscape,
      ),
      WelcomeFeatureCard(
        icon: Icons.notifications_outlined,
        title: l10n.onboardingWelcomeDailyReminders,
        isLandscape: isLandscape,
      ),
      WelcomeFeatureCard(
        icon: Icons.lock_outline,
        title: l10n.onboardingWelcomePrivacy,
        isLandscape: isLandscape,
      ),
    ];

    final Widget cardsContent;
    if (isLandscape) {
      cardsContent = Column(
        children: [
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
        ],
      );
    } else {
      cardsContent = Column(
        children: [
          for (int i = 0; i < featureCards.length; i++) ...[
            featureCards[i],
            if (i < featureCards.length - 1) const SizedBox(height: 12.0),
          ],
        ],
      );
    }

    return OnboardingStepLayout(
      titleWidget: Text(
        l10n.onboardingWelcomeTitle,
        style:
            (isLandscape
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      subtitleWidget: Column(
        children: [
          const SizedBox(height: 8.0),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: cardsContent,
      footer: FilledButton(
        key: const Key('welcome_step_start_button'),
        onPressed: onNext,
        child: Text(l10n.onboardingWelcomeStart),
      ),
    );
  }
}
