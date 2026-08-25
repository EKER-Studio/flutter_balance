import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational app bar for the onboarding wizard displaying a step counter and linear progress indicator.
class OnboardingAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The 1-based index of the currently active step.
  final int displayStep;

  /// The total number of configuration steps excluding welcome.
  final int displayTotalSteps;

  /// The progress fraction between 0.0 and 1.0.
  final double progress;

  final VoidCallback onBackPressed;

  const OnboardingAppBar({
    super.key,
    required this.displayStep,
    required this.displayTotalSteps,
    required this.progress,
    required this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AppBar(
      toolbarHeight: 48.0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.previousStepTooltip,
        onPressed: onBackPressed,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8.0),
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 6.0),
          child: Semantics(
            label: l10n.stepOf(displayStep, displayTotalSteps),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4.0,
                borderRadius: BorderRadius.circular(4.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
