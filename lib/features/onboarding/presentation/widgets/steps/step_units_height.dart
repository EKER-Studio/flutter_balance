import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/core/presentation/core/clamped_layout.dart';
import 'package:flutter/material.dart';

/// Form widget for Step 1 of the onboarding wizard: choosing a unit system
/// and entering the user's height.
///
/// Persists the choice by advancing via [onNext] with the selected
/// [MeasurementUnit] and a validated height in cm; the wizard screen writes
/// both into [AppSettingsBloc] and syncs the height into `WeightBloc` before
/// the initial-weight step runs. Validation accepts metric heights between
/// [AppSettingsState.minHeightCm] and [AppSettingsState.maxHeightCm], or 1-8
/// feet with 0-11.99 inches in imperial mode; an invalid value shows an
/// inline range error and blocks advancing. Toggling the unit converts the
/// current height into the new system, and the active field requests focus
/// whenever the step becomes the current page.
class StepUnitsHeight extends StatefulWidget {
  /// Initial measurement unit system preference.
  final MeasurementUnit initialUnit;

  /// Initial height in centimeters, or `null` if not yet set.
  final double? initialHeightCm;

  /// Whether this step is currently visible in the PageView.
  final bool isCurrentPage;

  /// Callback invoked when the user proceeds to the next step.
  ///
  /// Passes the chosen measurement unit system and a validated height in cm.
  final void Function(MeasurementUnit unit, double heightCm) onNext;

  /// Creates a [StepUnitsHeight] widget.
  const StepUnitsHeight({
    super.key,
    required this.initialUnit,
    required this.initialHeightCm,
    required this.isCurrentPage,
    required this.onNext,
  });

  @override
  State<StepUnitsHeight> createState() => _StepUnitsHeightState();
}

class _StepUnitsHeightState extends State<StepUnitsHeight> {
  late MeasurementUnit _selectedUnit;

  late final TextEditingController _cmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;

  late final FocusNode _cmFocusNode;
  late final FocusNode _feetFocusNode;
  late final FocusNode _inchesFocusNode;

  String? _cmErrorText;
  String? _imperialErrorText;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;

    _cmFocusNode = FocusNode();
    _feetFocusNode = FocusNode();
    _inchesFocusNode = FocusNode();

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

    if (widget.isCurrentPage) {
      _requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant StepUnitsHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCurrentPage && widget.isCurrentPage) {
      _requestFocus();
    }
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetNode = _selectedUnit == MeasurementUnit.metric
          ? _cmFocusNode
          : _feetFocusNode;
      targetNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _cmFocusNode.dispose();
    _feetFocusNode.dispose();
    _inchesFocusNode.dispose();
    super.dispose();
  }

  /// Converts the active unit inputs into centimeters, or `null` when invalid.
  double? _calculateHeightCm() {
    if (_selectedUnit == MeasurementUnit.metric) {
      final cm = double.tryParse(
        _cmController.text.trim().replaceAll(',', '.'),
      );
      if (cm != null &&
          cm >= AppSettingsState.minHeightCm &&
          cm <= AppSettingsState.maxHeightCm) {
        return cm;
      }
      return null;
    } else {
      final feet = double.tryParse(
        _feetController.text.trim().replaceAll(',', '.'),
      );
      final inches = double.tryParse(
        _inchesController.text.trim().replaceAll(',', '.'),
      );
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
      _cmErrorText = null;
      _imperialErrorText = null;
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
    // Defer focus request past the current frame so setState completes first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetNode = newUnit == MeasurementUnit.metric
          ? _cmFocusNode
          : _feetFocusNode;
      if (!targetNode.hasFocus) {
        targetNode.requestFocus();
      }
    });
  }

  /// Validates the form and invokes [StepUnitsHeight.onNext] on success.
  void _handleNext() {
    final heightCm = _calculateHeightCm();
    if (heightCm == null) {
      setState(() {
        if (_selectedUnit == MeasurementUnit.metric) {
          _cmErrorText = AppLocalizations.of(context).heightRangeError;
        } else {
          _imperialErrorText = AppLocalizations.of(context).heightRangeError;
        }
      });
    } else {
      widget.onNext(_selectedUnit, heightCm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isMetricError = _cmErrorText != null;
    final isImperialError = _imperialErrorText != null;

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
            l10n.onboardingUnitsHeightTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.onboardingUnitsHeightSubtitle,
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
            TextField(
              key: const Key('height_cm_input'),
              controller: _cmController,
              focusNode: _cmFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.heightCmLabel,
                hintText: l10n.heightHint,
                enabledBorder: isMetricError ? errorOutline : null,
                focusedBorder: isMetricError ? errorOutline : null,
              ),
              onChanged: (_) {
                if (_cmErrorText != null) {
                  setState(() => _cmErrorText = null);
                }
              },
              onSubmitted: (_) => _handleNext(),
            ),
            const SizedBox(height: 8),
            Text(
              isMetricError
                  ? _cmErrorText!
                  : l10n.heightRangeHint(
                      AppSettingsState.minHeightCm.toStringAsFixed(0),
                      AppSettingsState.maxHeightCm.toStringAsFixed(0),
                    ),
              style: TextStyle(
                color: isMetricError
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isMetricError ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('height_feet_input'),
                    controller: _feetController,
                    focusNode: _feetFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.feetLabel,
                      suffixText: 'ft',
                      enabledBorder: isImperialError ? errorOutline : null,
                      focusedBorder: isImperialError ? errorOutline : null,
                    ),
                    onChanged: (_) {
                      if (_imperialErrorText != null) {
                        setState(() => _imperialErrorText = null);
                      }
                    },
                    onSubmitted: (_) => _handleNext(),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    key: const Key('height_inches_input'),
                    controller: _inchesController,
                    focusNode: _inchesFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.inchesLabel,
                      suffixText: 'in',
                      enabledBorder: isImperialError ? errorOutline : null,
                      focusedBorder: isImperialError ? errorOutline : null,
                    ),
                    onChanged: (_) {
                      if (_imperialErrorText != null) {
                        setState(() => _imperialErrorText = null);
                      }
                    },
                    onSubmitted: (_) => _handleNext(),
                  ),
                ),
              ],
            ),
            if (isImperialError) ...[
              const SizedBox(height: 8),
              Text(
                _imperialErrorText!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48.0),
            child: FilledButton(onPressed: _handleNext, child: Text(l10n.next)),
          ),
        ],
      ),
    );
  }
}
