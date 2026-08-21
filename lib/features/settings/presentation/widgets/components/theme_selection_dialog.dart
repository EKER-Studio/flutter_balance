import 'package:flutter/material.dart';
import 'package:balance/core/presentation/utils/app_theme_mode_localizer.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog for choosing the app theme mode (system, light, dark).
class ThemeSelectionDialog extends StatelessWidget {
  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onSelected;

  const ThemeSelectionDialog({
    super.key,
    required this.currentMode,
    required this.onSelected,
  });

  /// Shows the dialog and calls [onSelected] when a mode is picked.
  static Future<void> show(
    BuildContext context, {
    required AppThemeMode currentMode,
    required ValueChanged<AppThemeMode> onSelected,
  }) async {
    AppAnalytics.logSettingsThemeDialogOpened(currentMode.name);
    bool selected = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => ThemeSelectionDialog(
        currentMode: currentMode,
        onSelected: (mode) {
          selected = true;
          onSelected(mode);
          Navigator.pop(ctx);
        },
      ),
    );
    if (!selected) {
      AppAnalytics.logSettingsThemeDialogCancelled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SimpleDialog(
      title: Text(l10n.theme),
      children: [
        RadioGroup<AppThemeMode>(
          groupValue: currentMode,
          onChanged: (value) {
            if (value != null) {
              onSelected(value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in AppThemeMode.values)
                RadioListTile<AppThemeMode>(
                  title: Text(mode.localizedName(l10n)),
                  value: mode,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
