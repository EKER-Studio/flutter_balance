import 'package:flutter/material.dart';

/// Full-screen centered message with icon, title, subtitle, and optional CTA button.
///
/// Used for empty states, welcome screens, and error states with consistent layout.
class StateMessageCard extends StatelessWidget {
  /// Creates [StateMessageCard].
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

  final IconData icon;
  final Color iconColor;
  final Color iconContainerColor;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
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
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: iconColor),
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
