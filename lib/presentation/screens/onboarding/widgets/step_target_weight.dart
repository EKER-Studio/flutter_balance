import 'package:flutter/material.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Form widget for Step 2 of the onboarding wizard: setting an optional target weight.
class StepTargetWeight extends StatefulWidget {
  /// The user's active measurement unit system.
  final MeasurementUnit unit;

  /// Initial target weight in kg (if already set).
  final double? initialTargetWeightKg;

  /// Callback invoked when the user submits or skips this step.
  ///
  /// Passes the target weight in kg, or `null` if no target weight is set.
  final void Function(double? targetWeightKg) onNext;

  /// Creates a [StepTargetWeight] widget.
  const StepTargetWeight({
    super.key,
    required this.unit,
    this.initialTargetWeightKg,
    required this.onNext,
  });

  @override
  State<StepTargetWeight> createState() => _StepTargetWeightState();
}

class _StepTargetWeightState extends State<StepTargetWeight> {
  late final TextEditingController _weightController;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    String initialText = '';
    if (widget.initialTargetWeightKg != null &&
        widget.initialTargetWeightKg! > 0) {
      if (widget.unit == MeasurementUnit.imperial) {
        final lbs = kgToLbs(widget.initialTargetWeightKg!);
        initialText = lbs.toStringAsFixed(1);
      } else {
        initialText = widget.initialTargetWeightKg!.toStringAsFixed(1);
      }
    }

    _weightController = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  /// Parses the target weight input into kilograms, or `null` when empty or
  /// invalid.
  double? _parseTargetWeightKg() {
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
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
      return;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0 || parsed > 500) {
      if (_errorText == null) {
        setState(() => _errorText = 'Please enter a valid weight (> 0)');
      }
    } else {
      if (_errorText != null) {
        setState(() => _errorText = null);
      }
    }
  }

  void _handleNext() {
    final weightKg = _parseTargetWeightKg();
    widget.onNext(weightKg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isImperial = widget.unit == MeasurementUnit.imperial;
    final unitSuffix = isImperial ? 'lbs' : 'kg';

    final isError = _errorText != null;
    final isNextEnabled = !isError;

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
            l10n.targetWeightOptionalTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.targetWeightStepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24.0),
          TextField(
            key: const Key('target_weight_input'),
            controller: _weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l10n.targetWeightDialogTitle} ($unitSuffix)',
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
            isError ? _errorText! : l10n.targetWeightOptionalHint,
            style: TextStyle(
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isError ? FontWeight.w500 : FontWeight.w400,
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
