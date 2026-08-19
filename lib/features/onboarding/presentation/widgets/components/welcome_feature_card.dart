import 'package:flutter/material.dart';

/// A presentational card highlighting an onboarding feature with an icon and title.
class WelcomeFeatureCard extends StatelessWidget {
  /// The icon representing the feature.
  final IconData icon;

  /// The title label of the feature.
  final String title;

  /// Whether the screen is in landscape mode.
  final bool isLandscape;

  /// Creates a [WelcomeFeatureCard] widget.
  const WelcomeFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isLandscape ? 10.0 : 12.0,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                padding: EdgeInsets.all(isLandscape ? 6.0 : 8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: isLandscape ? 18.0 : 20.0,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: (isLandscape
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
}
