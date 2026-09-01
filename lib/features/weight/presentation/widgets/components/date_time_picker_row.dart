import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational row widget displaying interactive date and time pickers with semantic labeling and error hints.
class DateTimePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String? dateTimeError;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const DateTimePickerRow({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.dateTimeError,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(selectedDate);
    final timeStr = selectedTime.format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '${l10n.measurementDate}: $dateStr',
                hint: l10n.doubleTapToOpenCalendarHint,
                child: InkWell(
                  onTap: onPickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.measurementDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        16,
                        12,
                        12,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        dateStr,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: '${l10n.measurementTime}: $timeStr',
                hint: l10n.doubleTapToChangeTimeHint,
                child: InkWell(
                  onTap: onPickTime,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.measurementTime,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(
                        Icons.access_time_outlined,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        16,
                        12,
                        12,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        timeStr,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (dateTimeError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12.0),
            child: Text(
              dateTimeError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
