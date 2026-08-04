import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Form widget for Step 3 of the onboarding wizard: logging initial weight.
class StepInitialWeight extends StatefulWidget {
  /// The user's active measurement unit system.
  final MeasurementUnit unit;

  /// Callback invoked when setup is completed.
  ///
  /// Passes the initial weight in kg and the chosen measurement timestamp.
  final void Function(double weightKg, DateTime timestamp) onComplete;

  /// Creates a [StepInitialWeight] widget.
  const StepInitialWeight({
    super.key,
    required this.unit,
    required this.onComplete,
  });

  @override
  State<StepInitialWeight> createState() => _StepInitialWeightState();
}

class _StepInitialWeightState extends State<StepInitialWeight> {
  final TextEditingController _weightController = TextEditingController();
  DateTime _selectedTimestamp = DateTime.now();
  String? _errorText;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// Shows the date and time pickers and updates the selected timestamp.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTimestamp,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedTimestamp = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  /// Parses the weight input into kilograms, or `null` when invalid.
  double? _parseWeightKg() {
    final text = _weightController.text.trim();
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0 || parsed > 500) return null;

    if (widget.unit == MeasurementUnit.imperial) {
      return lbsToKg(parsed);
    }
    return parsed;
  }

  void _validate(String value) {
    setState(() {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        _errorText = 'Initial weight is required';
        return;
      }

      final parsed = double.tryParse(trimmed);
      if (parsed == null || parsed <= 0 || parsed > 500) {
        _errorText = 'Please enter a valid weight (> 0)';
      } else {
        _errorText = null;
      }
    });
  }

  void _handleComplete() {
    final weightKg = _parseWeightKg();
    if (weightKg != null) {
      widget.onComplete(weightKg, _selectedTimestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isImperial = widget.unit == MeasurementUnit.imperial;
    final unitSuffix = isImperial ? 'lbs' : 'kg';
    final formattedDate = DateFormat.yMMMd().add_jm().format(
      _selectedTimestamp,
    );

    final isError = _errorText != null;
    final isNextEnabled = _weightController.text.trim().isNotEmpty && !isError;

    final errorOutline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    );

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Initial Weight',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Log your starting weight measurement to begin tracking.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          TextField(
            key: const Key('initial_weight_input'),
            controller: _weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Current Weight ($unitSuffix)',
              suffixText: unitSuffix,
              enabledBorder: isError ? errorOutline : null,
              focusedBorder: isError ? errorOutline : null,
            ),
            onChanged: _validate,
            onSubmitted: (_) {
              if (isNextEnabled) _handleComplete();
            },
          ),
          const SizedBox(height: 8),
          Text(
            isError ? _errorText! : 'Enter your initial weight',
            style: TextStyle(
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isError ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            'Measurement Date & Time',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8.0),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const ExcludeSemantics(child: Icon(Icons.calendar_today)),
              label: Text(formattedDate),
            ),
          ),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: FilledButton(
              onPressed: isNextEnabled ? _handleComplete : null,
              child: Text(l10n.completeSetup),
            ),
          ),
        ],
      ),
    );
  }
}
