import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';

/// Modal dialog form for adding a new weight measurement with date, time, and note selection,
/// adhering to Material 3 dialog guidelines and accessibility (a11y) standards.
class AddWeightSheet extends StatefulWidget {
  /// Optional initial date/time for the measurement.
  final DateTime? initialDate;

  /// Creates [AddWeightSheet] with optional [initialDate].
  const AddWeightSheet({super.key, this.initialDate});

  @override
  State<AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends State<AddWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _dateTimeError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay.fromDateTime(initial);
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

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _validateDateTime();
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _validateDateTime();
      });
    }
  }

  void _validateDateTime() {
    if (_combinedDateTime.isAfter(DateTime.now())) {
      _dateTimeError = AppLocalizations.of(context).futureDateError;
    } else {
      _dateTimeError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;

    final dateStr = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(_selectedDate);

    final timeStr = _selectedTime.format(context);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.addWeight,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                            ),
                            child: Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodyLarge,
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
                            ),
                            child: Text(
                              timeStr,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_dateTimeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _dateTimeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _weightController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: unit == MeasurementUnit.imperial
                        ? l10n.weightInLbLabel
                        : l10n.weightInKgLabel,
                    hintText: l10n.weightHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.weightCannotBeEmpty;
                    }
                    final normalized = value.trim().replaceAll(',', '.');
                    final parsed = double.tryParse(normalized);
                    if (parsed == null) {
                      return l10n.enterValidNumber;
                    }
                    final weightKg = unit == MeasurementUnit.imperial
                        ? lbsToKg(parsed)
                        : parsed;
                    if (weightKg < 20 || weightKg > 300) {
                      return l10n.weightRangeError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _onSave,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSave() {
    FocusScope.of(context).unfocus();
    _validateDateTime();

    if (_dateTimeError != null) {
      setState(() {});
      return;
    }

    if (_formKey.currentState!.validate()) {
      final normalized = _weightController.text.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);

      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).enterValidNumber),
          ),
        );
        return;
      }

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
}
