import 'package:flutter/material.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Form widget for Step 1 of the onboarding wizard: selecting unit system and height.
class StepUnitsHeight extends StatefulWidget {
  /// Initial measurement unit system preference.
  final MeasurementUnit initialUnit;

  /// Initial height in centimeters.
  final double initialHeightCm;

  /// Callback invoked when the user proceeds to the next step.
  ///
  /// Passes the chosen [unit] system and valid [heightCm].
  final void Function(MeasurementUnit unit, double heightCm) onNext;

  /// Creates a [StepUnitsHeight] widget.
  const StepUnitsHeight({
    super.key,
    required this.initialUnit,
    required this.initialHeightCm,
    required this.onNext,
  });

  @override
  State<StepUnitsHeight> createState() => _StepUnitsHeightState();
}

class _StepUnitsHeightState extends State<StepUnitsHeight> {
  final _formKey = GlobalKey<FormState>();
  late MeasurementUnit _selectedUnit;

  late final TextEditingController _cmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;

  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;

    final initialCm = widget.initialHeightCm > 0
        ? widget.initialHeightCm
        : 170.0;

    _cmController = TextEditingController(
      text: initialCm.toStringAsFixed(0),
    );

    final [feet, inches] = cmToFeetInches(initialCm);
    _feetController = TextEditingController(text: feet.toInt().toString());
    _inchesController = TextEditingController(text: inches.round().toString());

    _validate();
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _validate() {
    final valid = _calculateHeightCm() != null;
    if (valid != _isValid) {
      setState(() {
        _isValid = valid;
      });
    }
  }

  double? _calculateHeightCm() {
    if (_selectedUnit == MeasurementUnit.metric) {
      final cm = double.tryParse(_cmController.text.trim());
      if (cm != null && cm >= 50.0 && cm <= 250.0) {
        return cm;
      }
      return null;
    } else {
      final feet = double.tryParse(_feetController.text.trim());
      final inches = double.tryParse(_inchesController.text.trim());
      if (feet != null &&
          inches != null &&
          feet >= 1 &&
          feet <= 8 &&
          inches >= 0 &&
          inches < 12) {
        final totalInches = (feet * 12) + inches;
        final cm = totalInches * 2.54;
        if (cm >= 50.0 && cm <= 250.0) {
          return cm;
        }
      }
      return null;
    }
  }

  void _onUnitChanged(MeasurementUnit newUnit) {
    if (newUnit == _selectedUnit) return;

    final currentCm = _calculateHeightCm();
    setState(() {
      _selectedUnit = newUnit;
      if (currentCm != null) {
        if (newUnit == MeasurementUnit.imperial) {
          final [feet, inches] = cmToFeetInches(currentCm);
          _feetController.text = feet.toInt().toString();
          _inchesController.text = inches.round().toString();
        } else {
          _cmController.text = currentCm.toStringAsFixed(0);
        }
      }
    });
    _validate();
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      final heightCm = _calculateHeightCm();
      if (heightCm != null) {
        widget.onNext(_selectedUnit, heightCm);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        onChanged: _validate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Units & Height',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Select your preferred unit system and enter your height.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),
            SegmentedButton<MeasurementUnit>(
              segments: const [
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.metric,
                  label: Text('Metric (kg / cm)'),
                  icon: Icon(Icons.straighten),
                ),
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.imperial,
                  label: Text('Imperial (lbs / ft-in)'),
                  icon: Icon(Icons.square_foot),
                ),
              ],
              selected: {_selectedUnit},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  _onUnitChanged(selection.first);
                }
              },
            ),
            const SizedBox(height: 24.0),
            if (_selectedUnit == MeasurementUnit.metric) ...[
              TextFormField(
                key: const Key('height_cm_input'),
                controller: _cmController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Height',
                  suffixText: 'cm',
                  border: OutlineInputBorder(),
                  helperText: 'Enter height between 50 and 250 cm',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 50.0 || parsed > 250.0) {
                    return 'Height must be between 50 and 250 cm';
                  }
                  return null;
                },
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('height_feet_input'),
                      controller: _feetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Feet',
                        suffixText: 'ft',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final feet = double.tryParse(value?.trim() ?? '');
                        if (feet == null || feet < 1 || feet > 8) {
                          return '1-8 ft';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: TextFormField(
                      key: const Key('height_inches_input'),
                      controller: _inchesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Inches',
                        suffixText: 'in',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final inches = double.tryParse(value?.trim() ?? '');
                        if (inches == null || inches < 0 || inches >= 12) {
                          return '0-11 in';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48.0),
              child: FilledButton(
                onPressed: _isValid ? _handleNext : null,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
