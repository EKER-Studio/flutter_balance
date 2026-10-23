import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/widgets/components/unit_selection_dialog.dart';

/// Shows the measurement unit selection dialog in the light theme.
@Preview(
  name: 'Unit Selection - Light',
  group: 'Balance Components',
  size: Size(430, 600),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
@Preview(
  name: 'Unit Selection - Dark',
  group: 'Balance Components',
  size: Size(430, 600),
  brightness: Brightness.dark,
  wrapper: darkPreviewWrapper,
)
Widget unitSelectionDialogPreview() {
  var currentUnit = MeasurementUnit.metric;
  return Scaffold(
    body: Center(
      child: StatefulBuilder(
        builder: (context, setState) => UnitSelectionDialog(
          currentUnit: currentUnit,
          onSelected: (unit) => setState(() => currentUnit = unit),
        ),
      ),
    ),
  );
}
