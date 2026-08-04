import 'package:flutter/material.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Form widget for Step 1 of the onboarding wizard: selecting unit system and height.
class StepUnitsHeight extends StatefulWidget {
  /// Initial measurement unit system preference.
  final MeasurementUnit initialUnit;

  /// Initial height in centimeters, or `null` if not yet set.
  final double? initialHeightCm;

  /// Callback invoked when the user proceeds to the next step.
  ///
  /// Passes the chosen measurement unit system and a validated height in cm.
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

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;

    final initialCm = widget.initialHeightCm;
    final hasHeight = initialCm != null && initialCm > 0;

    _cmController = TextEditingController(
      text: hasHeight ? initialCm.toStringAsFixed(0) : '',
    );

    final [feet, inches] = cmToFeetInches(hasHeight ? initialCm : 0.0);
    _feetController = TextEditingController(
      text: hasHeight ? feet.toInt().toString() : '',
    );
    _inchesController = TextEditingController(
      text: hasHeight ? inches.round().toString() : '',
    );
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  /// Converts the active unit inputs into centimeters, or `null` when invalid.
  double? _calculateHeightCm() {
    if (_selectedUnit == MeasurementUnit.metric) {
      final cm = double.tryParse(_cmController.text.trim());
      if (cm != null &&
          cm >= AppSettingsState.minHeightCm &&
          cm <= AppSettingsState.maxHeightCm) {
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
        if (cm >= AppSettingsState.minHeightCm &&
            cm <= AppSettingsState.maxHeightCm) {
          return cm;
        }
      }
      return null;
    }
  }

  /// Switches the input fields between metric and imperial, converting the
  /// current height value into the new unit system.
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
  }

  /// Validates the form and invokes [StepUnitsHeight.onNext] on success.
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
    final l10n = AppLocalizations.of(context);

    return ClampedLayout(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
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
              segments: [
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.metric,
                  label: Text(l10n.metricUnitOption),
                  icon: const ExcludeSemantics(child: Icon(Icons.straighten)),
                ),
                ButtonSegment<MeasurementUnit>(
                  value: MeasurementUnit.imperial,
                  label: Text(l10n.imperialUnitOption),
                  icon: const ExcludeSemantics(child: Icon(Icons.square_foot)),
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
                decoration: InputDecoration(
                  labelText: l10n.heightCmLabel,
                  hintText: l10n.heightHint,
                  helperText: '50 – 250 cm',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null ||
                      parsed < AppSettingsState.minHeightCm ||
                      parsed > AppSettingsState.maxHeightCm) {
                    return l10n.heightRangeError;
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
                onPressed: _handleNext,
                child: Text(l10n.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
