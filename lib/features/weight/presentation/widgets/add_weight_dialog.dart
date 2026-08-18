import 'package:balance/core/presentation/utils/picker_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';

/// A modal dialog form for adding a new weight measurement.
///
/// Validates the weight against [WeightEntry.minWeightKg] and
/// [WeightEntry.maxWeightKg], converts imperial input to kilograms, and
/// dispatches [AddWeight] to [WeightBloc] on save.
class AddWeightDialog extends StatefulWidget {
  /// The optional initial date/time for the measurement.
  final DateTime? initialDate;

  /// Creates an [AddWeightDialog] with an optional [initialDate].
  const AddWeightDialog({super.key, this.initialDate});

  @override
  State<AddWeightDialog> createState() => _AddWeightDialogState();
}

/// The state owning the form controllers, selected date/time, and save flow.
class _AddWeightDialogState extends State<AddWeightDialog> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _dateTimeError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialDate ?? now;

    _selectedDate = DateTime(initial.year, initial.month, initial.day);

    // Default to the current time unless a specific time was provided.
    if (widget.initialDate != null &&
        (initial.hour != 0 || initial.minute != 0)) {
      _selectedTime = TimeOfDay.fromDateTime(initial);
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  /// Shows the date picker and validates that the combined selection is not
  /// in the future.
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _validateDateTime();
      });
    }
  }

  /// Shows the time picker and validates the combined selection.
  Future<void> _pickTime(BuildContext context) async {
    final picked = await showSafeTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _validateDateTime();
      });
    }
  }

  /// Marks the combined date/time as invalid when it lies in the future.
  void _validateDateTime() {
    final now = DateTime.now().add(const Duration(minutes: 1));
    if (_combinedDateTime.isAfter(now)) {
      _dateTimeError = AppLocalizations.of(context).futureDateError;
    } else {
      _dateTimeError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hideChrome = isLandscape && isKeyboardOpen;

    final dateStr = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(_selectedDate);

    final timeStr = _selectedTime.format(context);

    final inputPadding = hideChrome
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsetsDirectional.fromSTEB(12, 16, 12, 12);

    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 32 : 24,
        vertical: isLandscape ? 8 : 24,
      ),
      title: hideChrome ? null : Text(l10n.addWeight),
      contentPadding: EdgeInsets.fromLTRB(
        24,
        hideChrome ? 8 : (isLandscape ? 12 : 20),
        24,
        hideChrome ? 8 : (isLandscape ? 12 : 20),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hideChrome) const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${l10n.measurementDate}: $dateStr',
                    hint: l10n.doubleTapToOpenCalendarHint,
                    child: InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.measurementDate,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                          isDense: hideChrome,
                          contentPadding: inputPadding,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
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
                      onTap: () => _pickTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.measurementTime,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(
                            Icons.access_time_outlined,
                            size: 20,
                          ),
                          isDense: hideChrome,
                          contentPadding: inputPadding,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
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
            if (_dateTimeError != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  _dateTimeError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            SizedBox(height: hideChrome ? 8 : 16),
            TextField(
              controller: _weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: unit == MeasurementUnit.imperial
                    ? l10n.weightInLbLabel
                    : l10n.weightInKgLabel,
                hintText: l10n.weightHint,
                border: const OutlineInputBorder(),
                errorText: _weightError != null ? "" : null,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
                isDense: hideChrome,
                contentPadding: inputPadding,
              ),
              onChanged: (_) {
                if (_weightError != null) setState(() => _weightError = null);
              },
            ),
            if (_weightError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  _weightError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12.0,
                  ),
                ),
              ),
            SizedBox(height: hideChrome ? 8 : 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                border: const OutlineInputBorder(),
                isDense: hideChrome,
                contentPadding: inputPadding,
              ),
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onSave(),
            ),
          ],
        ),
      ),
      actions: hideChrome
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(onPressed: _onSave, child: Text(l10n.save)),
            ],
    );
  }

  /// Validates the form and dispatches [AddWeight] to [WeightBloc] on success.
  void _validateWeight(String value) {
    if (value.trim().isEmpty) {
      _weightError = AppLocalizations.of(context).weightCannotBeEmpty;
      return;
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      _weightError = AppLocalizations.of(context).enterValidNumber;
      return;
    }
    final unit = context.read<AppSettingsBloc>().state.measurementUnit;
    final weightKg = unit == MeasurementUnit.imperial
        ? lbsToKg(parsed)
        : parsed;
    if (weightKg < WeightEntry.minWeightKg ||
        weightKg > WeightEntry.maxWeightKg) {
      _weightError = AppLocalizations.of(context).weightRangeError;
      return;
    }
    _weightError = null;
  }

  /// Validates the form and dispatches [AddWeight] to [WeightBloc] on success.
  void _onSave() {
    FocusScope.of(context).unfocus();
    _validateDateTime();
    _validateWeight(_weightController.text);

    if (_dateTimeError != null || _weightError != null) {
      setState(() {});
      return;
    }

    final normalized = _weightController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized)!;

    final unit = context.read<AppSettingsBloc>().state.measurementUnit;
    final weightKg = unit == MeasurementUnit.imperial
        ? lbsToKg(parsed)
        : parsed;
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    context.read<WeightBloc>().add(
      AddWeight(weightKg: weightKg, note: note, dateTime: _combinedDateTime),
    );

    Navigator.of(context).pop();
  }
}
