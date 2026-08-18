// Reusable settings tile following Material 3 List Item guidelines.

import 'package:flutter/material.dart';

/// A custom settings tile with an icon, title, supporting subtitle, optional trailing value, and chevron.
class CustomSettingsTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveSubtitle = subtitle ?? valueText;
    final effectiveColor = isError
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    final labelParts = [?sectionLabel, title, ?effectiveSubtitle];

    Widget? trailingWidget;
    if (showChevron) {
      trailingWidget = Icon(
        Icons.chevron_right,
        size: 20,
        color: effectiveColor,
      );
    }

    return Semantics(
      button: onTap != null,
      label: labelParts.join(', '),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: effectiveColor),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: isError ? colorScheme.error : null,
          ),
        ),
        subtitle: effectiveSubtitle != null
            ? Text(
                effectiveSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: effectiveColor,
                ),
              )
            : null,
        trailing: trailingWidget,
        onTap: onTap,
      ),
    );
  }
}
