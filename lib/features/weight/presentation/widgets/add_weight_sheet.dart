import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/utils/picker_helpers.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/widgets/components/date_time_picker_row.dart';
import 'package:balance/features/weight/presentation/widgets/components/weight_input_field.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A modal bottom sheet form for adding a new weight measurement.
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
class _AddWeightSheetState extends State<AddWeightSheet>
    with WidgetsBindingObserver {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _dateTimeError;
  String? _weightError;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lastOrientation ??= MediaQuery.orientationOf(context);
  }

  /// Dismisses the software keyboard when the device rotates so the sheet is
  /// rebuilt without an active IME connection, avoiding an ancestor lookup on
  /// an element deactivated during the rotation/keyboard teardown race.
  @override
  void didChangeMetrics() {
    final orientation = MediaQuery.orientationOf(context);
    if (orientation != _lastOrientation) {
      _lastOrientation = orientation;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    FocusScope.of(context).unfocus();
    AppAnalytics.logDialogAddWeightDatePickerOpened();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (!mounted) return;

    if (picked != null) {
      AppAnalytics.logDialogAddWeightDateChanged(
        picked.toIso8601String().substring(0, 10),
      );
      setState(() {
        _selectedDate = picked;
        _validateDateTime();
      });
    }
  }

  /// Shows the time picker and validates the combined selection.
  Future<void> _pickTime(BuildContext context) async {
    FocusScope.of(context).unfocus();
    AppAnalytics.logDialogAddWeightTimePickerOpened();
    final picked = await showSafeTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (!mounted) return;

    if (picked != null) {
      AppAnalytics.logDialogAddWeightTimeChanged(
        hour: picked.hour,
        minute: picked.minute,
      );
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
      AppAnalytics.logDialogAddWeightValidationError('future_date');
      _dateTimeError = AppLocalizations.of(context).futureDateError;
    } else {
      _dateTimeError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = context.watch<AppSettingsBloc>().state.measurementUnit;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.addWeight,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              DateTimePickerRow(
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                dateTimeError: _dateTimeError,
                onPickDate: () => _pickDate(context),
                onPickTime: () => _pickTime(context),
              ),
              const SizedBox(height: 16),
              WeightInputField(
                controller: _weightController,
                unit: unit,
                weightError: _weightError,
                onChanged: (_) {
                  if (_weightError != null) {
                    setState(() => _weightError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.noteLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    12,
                    16,
                    12,
                    12,
                  ),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  AppAnalytics.logDialogAddWeightNoteChanged(
                    val.trim().isNotEmpty,
                  );
                },
                onSubmitted: (_) => _onSave(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      AppAnalytics.logDialogAddWeightCancelled();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _onSave, child: Text(l10n.save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validates the form and dispatches [AddWeight] to [WeightBloc] on success.
  void _validateWeight(String value) {
    if (value.trim().isEmpty) {
      AppAnalytics.logDialogAddWeightValidationError('empty');
      _weightError = AppLocalizations.of(context).weightCannotBeEmpty;
      return;
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      AppAnalytics.logDialogAddWeightValidationError('invalid_number');
      _weightError = AppLocalizations.of(context).enterValidNumber;
      return;
    }
    final unit = context.read<AppSettingsBloc>().state.measurementUnit;
    final weightKg = unit == MeasurementUnit.imperial
        ? lbsToKg(parsed)
        : parsed;
    if (weightKg < WeightEntry.minWeightKg ||
        weightKg > WeightEntry.maxWeightKg) {
      AppAnalytics.logDialogAddWeightValidationError('range_error');
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

    final isPastDate = _combinedDateTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    AppAnalytics.logDialogAddWeightSaved(
      weightKg: weightKg,
      hasNote: note != null,
      isPastDate: isPastDate,
    );

    context.read<WeightBloc>().add(
      AddWeight(weightKg: weightKg, note: note, dateTime: _combinedDateTime),
    );

    Navigator.of(context).pop();
  }
}
