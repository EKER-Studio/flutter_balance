import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_step_layout.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/imperial_height_input.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/metric_height_input.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/onboarding_unit_selector.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/l10n/app_localizations.dart';

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
  final MeasurementUnit initialUnit;

  /// Initial height in centimeters, or `null` if not yet set.
  final double? initialHeightCm;

  /// Whether this step is currently visible in the PageView.
  final bool isCurrentPage;

  /// Callback invoked when the user proceeds to the next step.
  ///
  /// Passes the chosen measurement unit system and a validated height in cm.
  final void Function(MeasurementUnit unit, double heightCm) onNext;

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
  String? _cmErrorText;
  String? _imperialErrorText;

  late final TextEditingController _cmController;
  late final TextEditingController _feetController;
  late final TextEditingController _inchesController;

  late final FocusNode _cmFocusNode;
  late final FocusNode _feetFocusNode;
  late final FocusNode _inchesFocusNode;

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
      text: hasHeight ? formatHeightInput(initialCm) : '',
    );

    final [feet, inches] = cmToFeetInches(hasHeight ? initialCm : 0.0);
    _feetController = TextEditingController(
      text: hasHeight ? feet.toInt().toString() : '',
    );
    _inchesController = TextEditingController(
      text: hasHeight ? formatHeightInput(inches) : '',
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
      final cm = tryParseLocalizedNumber(_cmController.text);
      if (cm != null &&
          cm >= AppSettingsState.minHeightCm &&
          cm <= AppSettingsState.maxHeightCm) {
        return cm;
      }
      return null;
    } else {
      final cm = tryParseImperialHeightCm(
        _feetController.text,
        _inchesController.text,
      );
      if (cm != null &&
          cm >= AppSettingsState.minHeightCm &&
          cm <= AppSettingsState.maxHeightCm) {
        return cm;
      }
      return null;
    }
  }

  /// Classifies the current input for failure telemetry (categorical only,
  /// never the raw value).
  String _validationErrorType() {
    if (_selectedUnit == MeasurementUnit.metric) {
      return heightValidationErrorType(
        isEmpty: _cmController.text.trim().isEmpty,
        parsedValue: tryParseLocalizedNumber(_cmController.text),
      );
    }
    return heightValidationErrorType(
      isEmpty:
          _feetController.text.trim().isEmpty &&
          _inchesController.text.trim().isEmpty,
      parsedValue: tryParseImperialHeightCm(
        _feetController.text,
        _inchesController.text,
      ),
    );
  }

  /// Switches the input fields between metric and imperial, converting the
  /// current height value into the new unit system.
  void _onUnitChanged(MeasurementUnit newUnit) {
    if (newUnit == _selectedUnit) return;

    AppAnalytics.logOnboardingUnitsTabTapped(newUnit.name);
    final currentCm = _calculateHeightCm();
    setState(() {
      _cmErrorText = null;
      _imperialErrorText = null;
      _selectedUnit = newUnit;
      if (currentCm != null) {
        if (newUnit == MeasurementUnit.imperial) {
          final [feet, inches] = cmToFeetInches(currentCm);
          _feetController.text = feet.toInt().toString();
          _inchesController.text = formatHeightInput(inches);
        } else {
          _cmController.text = formatHeightInput(currentCm);
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

  void _handleNext() {
    final heightCm = _calculateHeightCm();
    if (heightCm != null) {
      widget.onNext(_selectedUnit, heightCm);
    } else {
      AppAnalytics.logOnboardingHeightValidationError(_validationErrorType());
      setState(() {
        if (_selectedUnit == MeasurementUnit.metric) {
          _cmErrorText = AppLocalizations.of(context).heightRangeError;
        } else {
          _imperialErrorText = AppLocalizations.of(context).heightRangeError;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return OnboardingStepLayout(
      title: l10n.onboardingUnitsHeightTitle,
      subtitle: l10n.onboardingUnitsHeightSubtitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingUnitSelector(
            selectedUnit: _selectedUnit,
            onUnitChanged: _onUnitChanged,
          ),
          SizedBox(height: isLandscape ? 8.0 : 20.0),
          if (_selectedUnit == MeasurementUnit.metric)
            MetricHeightInput(
              controller: _cmController,
              focusNode: _cmFocusNode,
              errorText: _cmErrorText,
              onChanged: (_) {
                if (_cmErrorText != null) {
                  setState(() => _cmErrorText = null);
                }
              },
              onSubmitted: _handleNext,
            )
          else
            ImperialHeightInput(
              feetController: _feetController,
              feetFocusNode: _feetFocusNode,
              inchesController: _inchesController,
              inchesFocusNode: _inchesFocusNode,
              errorText: _imperialErrorText,
              onChanged: () {
                if (_imperialErrorText != null) {
                  setState(() => _imperialErrorText = null);
                }
              },
              onSubmitted: _handleNext,
            ),
        ],
      ),
      footer: FilledButton(onPressed: _handleNext, child: Text(l10n.next)),
    );
  }
}
