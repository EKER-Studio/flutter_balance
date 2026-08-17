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
class AddWeightSheet extends StatefulWidget {
  /// The optional initial date/time for the measurement.
  final DateTime? initialDate;

  /// Creates an [AddWeightSheet] with an optional [initialDate].
  const AddWeightSheet({super.key, this.initialDate});

  @override
  State<AddWeightSheet> createState() => _AddWeightSheetState();
}

/// The state owning the form controllers, selected date/time, and save flow.
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
    final picked = await showTimePicker(
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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.monitor_weight_outlined,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
                      if (weightKg < WeightEntry.minWeightKg ||
                          weightKg > WeightEntry.maxWeightKg) {
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
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
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
      ),
    );
  }

  /// Validates the form and dispatches [AddWeight] to [WeightBloc] on success.
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
