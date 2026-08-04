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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;

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

  /// Validates the form and invokes [StepTargetWeight.onNext] on success.
  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      final weightKg = _parseTargetWeightKg();
      widget.onNext(weightKg);
    }
  }

  /// Skips the target weight and invokes [StepTargetWeight.onNext] with `null`.
  void _handleSkip() {
    widget.onNext(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isImperial = widget.unit == MeasurementUnit.imperial;
    final unitSuffix = isImperial ? 'lbs' : 'kg';

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Target Weight',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'What is your target weight goal? This step is optional.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),
            TextFormField(
              key: const Key('target_weight_input'),
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target Weight ($unitSuffix)',
                suffixText: unitSuffix,
                border: const OutlineInputBorder(),
                helperText: 'Optional — leave empty or tap Skip to set later',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null;

                final parsed = double.tryParse(trimmed);
                if (parsed == null || parsed <= 0 || parsed > 500) {
                  return 'Please enter a valid weight (> 0)';
                }
                return null;
              },
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: OutlinedButton(
                      onPressed: _handleSkip,
                      child: Text(l10n.skip),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48.0),
                    child: FilledButton(
                      onPressed: _handleNext,
                      child: Text(l10n.next),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
