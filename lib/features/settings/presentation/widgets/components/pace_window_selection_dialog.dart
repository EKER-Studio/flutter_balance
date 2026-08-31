import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog for choosing the time window (in days) used for weekly pace calculations.
class PaceWindowSelectionDialog extends StatelessWidget {
  /// The available window options in days.
  static const List<int> availableWindows = [7, 14, 30, 60, 90];

  /// The currently active window in days.
  final int currentDays;

  /// A callback invoked when a new window is picked.
  final ValueChanged<int> onSelected;

  const PaceWindowSelectionDialog({
    super.key,
    required this.currentDays,
    required this.onSelected,
  });

  /// Shows the dialog and calls [onSelected] when a window is picked.
  ///
  /// @param context The build context to mount the dialog.
  /// @param currentDays The active window in days.
  /// @param onSelected Callback with the selected window in days.
  static Future<void> show(
    BuildContext context, {
    required int currentDays,
    required ValueChanged<int> onSelected,
  }) async {
    AppAnalytics.logSettingsPaceWindowDialogOpened(currentDays);
    bool selected = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => PaceWindowSelectionDialog(
        currentDays: currentDays,
        onSelected: (days) {
          selected = true;
          Navigator.pop(ctx);
          onSelected(days);
        },
      ),
    );
    if (!selected) {
      AppAnalytics.logSettingsPaceWindowDialogCancelled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SimpleDialog(
      title: Text(l10n.paceWindow),
      children: [
        RadioGroup<int>(
          groupValue: currentDays,
          onChanged: (value) {
            if (value != null) {
              onSelected(value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final days in availableWindows)
                RadioListTile<int>(
                  title: Text(
                    days == 30
                        ? l10n.paceWindowDaysDefault(days)
                        : l10n.paceWindowDays(days),
                  ),
                  value: days,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
