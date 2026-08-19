import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational segmented control pill selector for choosing between metric and imperial unit systems.
class OnboardingUnitSelector extends StatelessWidget {
  /// The currently selected measurement unit system.
  final MeasurementUnit selectedUnit;

  /// Callback invoked when the user selects a different unit system.
  final ValueChanged<MeasurementUnit> onUnitChanged;

  /// Creates an [OnboardingUnitSelector] widget.
  const OnboardingUnitSelector({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PillSegmentedControl<MeasurementUnit>(
      selectedValue: selectedUnit,
      onValueChanged: onUnitChanged,
      segments: [
        PillSegment(
          value: MeasurementUnit.metric,
          label: l10n.metricUnitOption,
          key: const Key('unit_selector_metric'),
        ),
        PillSegment(
          value: MeasurementUnit.imperial,
          label: l10n.imperialUnitOption,
          key: const Key('unit_selector_imperial'),
        ),
      ],
    );
  }
}
