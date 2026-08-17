import 'package:flutter/material.dart';

/// Centered message states with icon, title, subtitle, and optional CTA button.
///
///// Used for empty states, welcome screens, and error states with consistent layout.
class StateMessageCard extends StatelessWidget {
  /// Creates a [StateMessageCard].
  ///
  /// [icon] and [iconContainerColor] control the icon circle appearance.
  /// [buttonLabel] and [onButtonPressed] must both be non-null for the button to appear.
  const StateMessageCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconContainerColor,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
    this.buttonIcon,
  });

  /// The icon rendered inside the circle.
  final IconData icon;

  /// The color of [icon].
  final Color iconColor;

  /// The background color of the icon circle.
  final Color iconContainerColor;

  /// The headline message text.
  final String title;

  /// The supporting message text below the title.
  final String subtitle;

  /// An optional label for the call-to-action button.
  final String? buttonLabel;

  /// An optional callback invoked when the button is pressed.
  final VoidCallback? onButtonPressed;

  /// An optional icon for the call-to-action button.
  final IconData? buttonIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: iconContainerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: iconColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              if (buttonLabel != null && onButtonPressed != null) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onButtonPressed,
                  icon: Icon(buttonIcon ?? Icons.add, size: 20),
                  label: Text(
                    buttonLabel!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
