import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';

/// Form widget for Step 3 of the onboarding wizard: logging the initial
/// weight and its measurement timestamp.
///
/// On success, [onNext] receives the weight in kg (converted from lbs when
/// the unit is imperial) and the selected timestamp; the wizard screen
/// dispatches `OnboardingInitialWeightSet`, which persists the entry into
/// `WeightBloc` right away. Input is validated on every keystroke: non-empty
/// and within 0-500 of the active unit (kg or lbs); otherwise the Next
/// button is disabled and an inline error is shown. The date/time button
/// opens the platform pickers to override the default "now" timestamp.
class StepInitialWeight extends StatefulWidget {
  /// The user's active measurement unit system.
  final MeasurementUnit unit;

  /// Pre-filled initial weight in kilograms (e.g. imported from CSV), or
  /// `null` when the input should start blank.
  final double? initialWeightKg;

  /// Timestamp of the pre-filled [initialWeightKg] (e.g. the imported
  /// entry's original date), or `null` to default to now. Ignored when
  /// [initialWeightKg] is `null`.
  final DateTime? initialTimestamp;

  /// Callback invoked when the user proceeds to the next step.
  ///
  /// Passes the initial weight in kg and the chosen measurement timestamp.
  final void Function(double weightKg, DateTime timestamp) onNext;

  /// Creates a [StepInitialWeight] widget.
  const StepInitialWeight({
    super.key,
    required this.unit,
    this.initialWeightKg,
    this.initialTimestamp,
    required this.onNext,
  });

  @override
  State<StepInitialWeight> createState() => _StepInitialWeightState();
}

class _StepInitialWeightState extends State<StepInitialWeight> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late DateTime _selectedTimestamp;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedTimestamp = widget.initialTimestamp ?? DateTime.now();

    // Request focus after the step's frame renders so the keyboard opens
    // exactly when the step becomes visible, never while it is offstage.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });

    final weightKg = widget.initialWeightKg;
    if (weightKg != null && weightKg > 0 && weightKg <= 500) {
      _weightController.text = widget.unit == MeasurementUnit.imperial
          ? kgToLbs(weightKg).toStringAsFixed(1)
          : weightKg.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Shows the date and time pickers (dates from 2000 up to today) and
  /// replaces the selected timestamp with the user's choice.
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
    final text = _weightController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0 || parsed > 500) return null;

    if (widget.unit == MeasurementUnit.imperial) {
      return lbsToKg(parsed);
    }
    return parsed;
  }

  /// Validates [value] on every keystroke and updates the inline error text.
  void _validate(String value) {
    setState(() {
      final trimmed = value.trim().replaceAll(',', '.');
      if (trimmed.isEmpty) {
        _errorText = AppLocalizations.of(context).initialWeightRequiredError;
        return;
      }

      final parsed = double.tryParse(trimmed);
      if (parsed == null || parsed <= 0 || parsed > 500) {
        _errorText = AppLocalizations.of(context).invalidPositiveNumber;
      } else {
        _errorText = null;
      }
    });
  }

  /// Invokes [StepInitialWeight.onNext] with the parsed weight and the
  /// selected timestamp when the input is valid.
  void _handleNext() {
    final weightKg = _parseWeightKg();
    if (weightKg != null) {
      widget.onNext(weightKg, _selectedTimestamp);
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
            l10n.initialWeightStepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.initialWeightStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          TextField(
            key: const Key('initial_weight_input'),
            controller: _weightController,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l10n.currentWeightLabel} ($unitSuffix)',
              suffixText: unitSuffix,
              enabledBorder: isError ? errorOutline : null,
              focusedBorder: isError ? errorOutline : null,
            ),
            onChanged: _validate,
            onSubmitted: (_) {
              if (isNextEnabled) _handleNext();
            },
          ),
          const SizedBox(height: 8),
          Text(
            isError ? _errorText! : l10n.enterInitialWeightHint,
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
            l10n.measurementDateTimeLabel,
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
              onPressed: isNextEnabled ? _handleNext : null,
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }
}
