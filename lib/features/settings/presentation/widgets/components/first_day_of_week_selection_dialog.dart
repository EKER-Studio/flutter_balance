import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/settings/presentation/utils/first_day_of_week_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog for choosing the calendar first day of week.
class FirstDayOfWeekSelectionDialog extends StatelessWidget {
  final FirstDayOfWeek currentFirstDay;
  final ValueChanged<FirstDayOfWeek> onSelected;

  const FirstDayOfWeekSelectionDialog({
    super.key,
    required this.currentFirstDay,
    required this.onSelected,
  });

  /// Shows the dialog and calls [onSelected] when a mode is picked.
  static Future<void> show(
    BuildContext context, {
    required FirstDayOfWeek currentFirstDay,
    required ValueChanged<FirstDayOfWeek> onSelected,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => FirstDayOfWeekSelectionDialog(
        currentFirstDay: currentFirstDay,
        onSelected: (mode) {
          onSelected(mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SimpleDialog(
      title: Text(l10n.firstDayOfWeek),
      children: [
        RadioGroup<FirstDayOfWeek>(
          groupValue: currentFirstDay,
          onChanged: (value) {
            if (value != null) {
              onSelected(value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in FirstDayOfWeek.values)
                RadioListTile<FirstDayOfWeek>(
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
