import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/widgets/components/theme_selection_dialog.dart';

/// Shows the theme selection dialog in the light theme.
@Preview(
  name: 'Theme Selection - Light',
  group: 'Balance Components',
  size: Size(430, 600),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
@Preview(
  name: 'Theme Selection - Dark',
  group: 'Balance Components',
  size: Size(430, 600),
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget themeSelectionDialogPreview() {
  var currentMode = AppThemeMode.system;
  return Scaffold(
    body: Center(
      child: StatefulBuilder(
        builder: (context, setState) => ThemeSelectionDialog(
          currentMode: currentMode,
          onSelected: (mode) => setState(() => currentMode = mode),
        ),
      ),
    ),
  );
}
