// Reusable settings tile following Material 3 List Item guidelines.

import 'package:flutter/material.dart';

/// A custom settings tile with an icon, title, supporting subtitle, optional trailing value, and chevron.
class CustomSettingsTile extends StatefulWidget {
  /// The leading icon rendered for this tile.
  final IconData icon;

  /// The tile title text.
  final String title;

  /// The optional supporting text shown below the [title].
  final String? subtitle;

  /// The optional trailing value text shown before the chevron.
  final String? valueText;

  /// The optional parent section label prepended to the accessibility label.
  final String? sectionLabel;

  /// The callback invoked when the tile is tapped.
  ///
  /// Passing `null` disables the tap interaction.
  final VoidCallback? onTap;

  /// Whether the tile is rendered with error colors.
  final bool isError;

  /// Whether a trailing chevron icon is shown.
  final bool showChevron;

  /// Creates a [CustomSettingsTile] with the given properties.
  const CustomSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueText,
    this.sectionLabel,
    this.onTap,
    this.isError = false,
    this.showChevron = true,
  });

  @override
  State<CustomSettingsTile> createState() => CustomSettingsTileState();
}

class CustomSettingsTileState extends State<CustomSettingsTile> {
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

    final effectiveColor = widget.isError
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    final labelParts = [?widget.sectionLabel, widget.title, ?widget.subtitle];

    Widget? trailingWidget;
    if (widget.valueText != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.valueText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.showChevron)
            ExcludeSemantics(
              child: Icon(Icons.chevron_right, size: 20, color: effectiveColor),
            ),
        ],
      );
    } else if (widget.showChevron) {
      trailingWidget = ExcludeSemantics(
        child: Icon(Icons.chevron_right, size: 20, color: effectiveColor),
      );
    }

    final tile = Semantics(
      button: widget.onTap != null,
      excludeSemantics: true,
      label: labelParts.join(', '),
      child: Focus(
        focusNode: _focusNode,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Icon(widget.icon, color: effectiveColor),
          title: Text(
            widget.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: widget.isError ? colorScheme.error : null,
            ),
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: effectiveColor,
                  ),
                )
              : null,
          trailing: trailingWidget,
          onTap: widget.onTap,
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
