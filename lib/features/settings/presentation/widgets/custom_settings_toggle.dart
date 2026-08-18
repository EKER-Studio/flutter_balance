// Settings list tile with a trailing switch for boolean preferences.

import 'package:flutter/material.dart';

/// A widget that represents a settings list tile with a trailing switch, used for boolean preferences.
class CustomSettingsToggle extends StatelessWidget {
  /// The leading icon rendered for this tile.
  final IconData icon;

  /// The tile title text.
  final String title;

  /// The optional supporting text below the [title].
  final String? subtitle;

  /// The current switch state.
  final bool value;

  /// The callback invoked when the switch is toggled.
  ///
  /// Passing `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// The optional parent section label prepended to the accessibility label.
  final String? sectionLabel;

  /// Creates a [CustomSettingsToggle] with the given properties.
  const CustomSettingsToggle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.sectionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelParts = [
      if (sectionLabel != null) sectionLabel!,
      title,
      if (subtitle != null) subtitle!,
    ];

    return Semantics(
      label: labelParts.join(', '),
      child: SwitchListTile.adaptive(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        secondary: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
