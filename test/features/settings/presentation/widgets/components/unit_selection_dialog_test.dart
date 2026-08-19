import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/widgets/components/unit_selection_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  group('UnitSelectionDialog', () {
    testWidgets('renders unit choices and calls onSelected on choice', (
      tester,
    ) async {
      MeasurementUnit? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  UnitSelectionDialog.show(
                    context,
                    currentUnit: MeasurementUnit.metric,
                    onSelected: (unit) => selectedUnit = unit,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Measurement Unit'), findsOneWidget);
      expect(find.text('Metric (kg, cm)'), findsOneWidget);
      expect(find.text('Imperial (lb, ft/in)'), findsOneWidget);

      await tester.tap(find.text('Imperial (lb, ft/in)'));
      await tester.pumpAndSettle();

      expect(selectedUnit, equals(MeasurementUnit.imperial));
      expect(find.byType(UnitSelectionDialog), findsNothing);
    });
  });
}
