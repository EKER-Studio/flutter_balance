// Settings list tile with a trailing switch for boolean preferences.

import 'package:flutter/material.dart';

/// A widget that represents a settings list tile with a trailing switch, used for boolean preferences.
class CustomSettingsToggle extends StatefulWidget {
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
  State<CustomSettingsToggle> createState() => CustomSettingsToggleState();
}

/// State for [CustomSettingsToggle] managing focus and hover state listeners.
class CustomSettingsToggleState extends State<CustomSettingsToggle> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final labelParts = [?widget.sectionLabel, widget.title, ?widget.subtitle];

    final tile = Semantics(
      toggled: widget.value,
      label: labelParts.join(', '),
      child: Focus(
        focusNode: _focusNode,
        child: SwitchListTile.adaptive(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          secondary: ExcludeSemantics(
            child: Icon(widget.icon, color: colorScheme.onSurfaceVariant),
          ),
          title: Text(
            widget.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );

    if (_isFocused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: tile,
      );
    }

    return tile;
  }
}
