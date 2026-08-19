import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog for choosing the measurement unit system.
class UnitSelectionDialog extends StatelessWidget {
  /// The current active measurement unit.
  final MeasurementUnit currentUnit;

  /// Callback when a measurement unit is selected.
  final ValueChanged<MeasurementUnit> onSelected;

  /// Creates a [UnitSelectionDialog] widget.
  const UnitSelectionDialog({
    super.key,
    required this.currentUnit,
    required this.onSelected,
  });

  /// Shows the dialog and calls [onSelected] when a unit is picked.
  static Future<void> show(
    BuildContext context, {
    required MeasurementUnit currentUnit,
    required ValueChanged<MeasurementUnit> onSelected,
  }) async {
    AppAnalytics.logSettingsUnitDialogOpened(currentUnit.name);
    bool selected = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => UnitSelectionDialog(
        currentUnit: currentUnit,
        onSelected: (unit) {
          selected = true;
          onSelected(unit);
          Navigator.pop(ctx);
        },
      ),
    );
    if (!selected) {
      AppAnalytics.logSettingsUnitDialogCancelled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.measurementUnit),
      content: PillSegmentedControl<MeasurementUnit>(
        selectedValue: currentUnit,
        onValueChanged: onSelected,
        segments: [
          for (final unit in MeasurementUnit.values)
            PillSegment(value: unit, label: unit.localizedName(l10n)),
        ],
      ),
    );
  }
}
