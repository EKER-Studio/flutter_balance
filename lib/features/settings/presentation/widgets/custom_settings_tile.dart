import 'package:flutter/material.dart';

class CustomSettingsTile extends StatefulWidget {
  /// Leading icon rendered inside a circular container.
  final IconData icon;

  /// Tile title text.
  final String title;

  /// Optional supporting text shown below the title.
  final String? subtitle;

  /// Optional trailing value text shown before the chevron.
  final String? valueText;

  /// Callback invoked when the tile is tapped; `null` disables the tap.
  final VoidCallback? onTap;

  /// Whether the tile is rendered with error colors.
  final bool isError;

  /// Whether a trailing chevron icon is shown.
  final bool showChevron;

  /// Optional parent section label prepended to the accessibility label.
  final String? sectionLabel;

  /// Creates a [CustomSettingsTile] with the given properties.
  const CustomSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.valueText,
    this.onTap,
    this.isError = false,
    this.showChevron = true,
    this.sectionLabel,
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
        child: Icon(
          widget.icon,
          size: 24,
          color: widget.isError
              ? colorScheme.error
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );

    final titleWidget = Text(
      widget.title,
      style: textTheme.bodyLarge?.copyWith(
        color: widget.isError ? colorScheme.error : colorScheme.onSurface,
      ),
    );

    final subtitleWidget = widget.subtitle != null
        ? Text(
            widget.subtitle!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        : null;

    Widget? trailingWidget;
    if (widget.valueText != null) {
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              widget.valueText!,
              style: textTheme.bodyMedium?.copyWith(
                color: widget.isError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.showChevron)
            ExcludeSemantics(
              child: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    } else if (widget.showChevron) {
      trailingWidget = ExcludeSemantics(
        child: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final labelParts = <String>[
      if (widget.sectionLabel != null) widget.sectionLabel!,
      widget.title,
      if (widget.subtitle != null) widget.subtitle!,
    ];

    final tile = Semantics(
      button: true,
      excludeSemantics: labelParts.length > 1,
      label: labelParts.length > 1 ? labelParts.join(', ') : null,
      child: Focus(
        focusNode: _focusNode,
        child: Theme(
          data: Theme.of(context).copyWith(
            highlightColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.primary.withValues(alpha: 0.08),
            splashColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: ListTile(
            shape: shape,
            hoverColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.08)
                : colorScheme.onSurface.withValues(alpha: 0.08),
            focusColor: widget.isError
                ? colorScheme.error.withValues(alpha: 0.12)
                : colorScheme.onSurface.withValues(alpha: 0.12),
            minLeadingWidth: 40,
            minVerticalPadding: 8,
            onTap: widget.onTap,
            leading: leading,
            title: titleWidget,
            subtitle: subtitleWidget,
            trailing: trailingWidget,
          ),
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
