import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational button/decorator for picking date and time for initial weight onboarding.
class InitialWeightDateTimePicker extends StatelessWidget {
  final DateTime selectedTimestamp;
  final VoidCallback onTap;

  const InitialWeightDateTimePicker({
    super.key,
    required this.selectedTimestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final formattedDate = DateFormat.yMMMd(
      l10n.localeName,
    ).add_jm().format(selectedTimestamp);

    return InkWell(
      key: const Key('initial_weight_date_picker'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.measurementDateTimeLabel,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formattedDate, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}
