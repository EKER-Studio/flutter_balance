import 'package:flutter/material.dart';

/// A reusable, accessible settings row widget.
///
/// Combines a leading icon, title, optional subtitle, optional current value text,
/// and an optional trailing chevron. Supports semantic grouping for screen readers,
/// error styling, and focused state highlighting.
class CustomSettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? valueText;
  final String? sectionLabel;
  final VoidCallback? onTap;
  final bool isError;
  final bool showChevron;

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

/// State for [CustomSettingsTile] managing focus and hover state listeners.
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

    final labelParts = [
      ?widget.sectionLabel,
      widget.title,
      ?widget.valueText,
      ?widget.subtitle,
    ];

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevronIcon = isRtl ? Icons.chevron_left : Icons.chevron_right;

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
              child: Icon(chevronIcon, size: 20, color: effectiveColor),
            ),
        ],
      );
    } else if (widget.showChevron) {
      trailingWidget = ExcludeSemantics(
        child: Icon(chevronIcon, size: 20, color: effectiveColor),
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
            borderRadius: BorderRadius.circular(16),
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
      return DecoratedBox(
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
