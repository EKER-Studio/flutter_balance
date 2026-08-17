// Settings list tile with a trailing switch for boolean preferences.

import 'package:flutter/material.dart';

/// A widget that represents a settings list tile with a trailing switch, used for boolean preferences.
class CustomSettingsToggle extends StatefulWidget {
  /// The leading icon rendered inside a circular container.
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final leading = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, size: 24, color: colorScheme.onSurfaceVariant),
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final tile = Semantics(
      toggled: widget.value,
      label: widget.sectionLabel != null
          ? '${widget.sectionLabel}, ${widget.title}'
          : widget.title,
      child: Focus(
        focusNode: _focusNode,
        child: SwitchListTile.adaptive(
          shape: shape,
          tileColor: Colors.transparent,
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.08),
          minVerticalPadding: 8,
          title: Text(
            widget.title,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          secondary: leading,
          value: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );

    if (_isFocused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: tile,
      );
    }

    return tile;
  }
}
