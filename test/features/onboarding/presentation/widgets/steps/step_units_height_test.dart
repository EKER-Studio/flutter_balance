import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  (String, String) l10nStrings(WidgetTester tester) {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(StepUnitsHeight)),
    );
    return (l10n.heightRangeError, l10n.next);
  }

  bool fieldFocused(WidgetTester tester, Key key) {
    final field = tester.widget<TextField>(find.byKey(key));
    return field.focusNode?.hasFocus ?? false;
  }

  group('StepUnitsHeight imperial flows', () {
    testWidgets('prefills imperial fields and focuses feet from an '
        'imperial height', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: 175.0,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('height_feet_input')), findsOneWidget);
      final feet = tester.widget<TextField>(
        find.byKey(const Key('height_feet_input')),
      );
      expect(feet.controller?.text, '5');
      final inches = tester.widget<TextField>(
        find.byKey(const Key('height_inches_input')),
      );
      expect(inches.controller?.text, '9');
      expect(fieldFocused(tester, const Key('height_feet_input')), isTrue);
    });

    testWidgets('converts valid imperial input and invokes onNext', (
      tester,
    ) async {
      MeasurementUnit? selectedUnit;
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (unit, height) {
              selectedUnit = unit;
              selectedHeight = height;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('height_feet_input')), '5');
      await tester.enterText(find.byKey(const Key('height_inches_input')), '9');
      await tester.tap(find.text(l10nStrings(tester).$2));
      await tester.pumpAndSettle();

      expect(selectedUnit, MeasurementUnit.imperial);
      expect(selectedHeight, closeTo(175.26, 0.01));
    });

    testWidgets('parses comma decimals in imperial fields', (tester) async {
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (unit, height) => selectedHeight = height,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('height_feet_input')), '5,5');
      await tester.enterText(find.byKey(const Key('height_inches_input')), '0');
      await tester.tap(find.text(l10nStrings(tester).$2));
      await tester.pumpAndSettle();

      expect(selectedHeight, closeTo(167.64, 0.01));
    });

    testWidgets('shows error for zero or empty feet and clears on typing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final (errorText, next) = l10nStrings(tester);

      await tester.enterText(find.byKey(const Key('height_feet_input')), '0');
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();

      expect(find.text(errorText), findsWidgets);
      expect(fieldFocused(tester, const Key('height_feet_input')), isTrue);

      // Typing into the feet field clears the imperial error.
      await tester.enterText(find.byKey(const Key('height_feet_input')), '5');
      await tester.pumpAndSettle();
      expect(find.text(errorText), findsNothing);

      // Re-trigger the error, then clear it from the inches field.
      await tester.enterText(find.byKey(const Key('height_feet_input')), '0');
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();
      expect(find.text(errorText), findsWidgets);
      await tester.enterText(find.byKey(const Key('height_inches_input')), '1');
      await tester.pumpAndSettle();
      expect(find.text(errorText), findsNothing);
    });

    testWidgets('rejects out-of-range feet, inches, and combined heights', (
      tester,
    ) async {
      Future<void> pumpImperial(double? feet, double? inches) async {
        await tester.pumpWidget(
          buildApp(
            StepUnitsHeight(
              initialUnit: MeasurementUnit.imperial,
              initialHeightCm: null,
              isCurrentPage: true,
              onNext: (_, _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final (errorText, next) = l10nStrings(tester);
        final feetField = find.byKey(const Key('height_feet_input'));
        final inchesField = find.byKey(const Key('height_inches_input'));
        if (feet != null) {
          await tester.enterText(feetField, feet.toString());
        }
        if (inches != null) {
          await tester.enterText(inchesField, inches.toString());
        }
        await tester.tap(find.text(next));
        await tester.pumpAndSettle();
        expect(find.text(errorText), findsWidgets);
      }

      // Feet above the allowed range.
      await pumpImperial(9, 0);
      // Negative inches input.
      await pumpImperial(5, -1);
      // Feet/inches combination below the minimum height in cm (1 ft).
      await pumpImperial(1, 0);
      // Completely empty imperial form.
      await pumpImperial(null, null);
    });

    testWidgets('switches imperial to metric converting the height', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: 175.0,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Metric (kg, cm)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('height_cm_input')), findsOneWidget);
      final cm = tester.widget<TextField>(
        find.byKey(const Key('height_cm_input')),
      );
      expect(cm.controller?.text, '175');
      expect(fieldFocused(tester, const Key('height_cm_input')), isTrue);
    });

    testWidgets('keeps imperial fields empty when switching with an invalid '
        'metric height', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(
        find.byKey(const Key('height_cm_input')),
        'not a number',
      );
      await tester.tap(find.text('Imperial (lb, ft/in)'));
      await tester.pumpAndSettle();

      final feet = tester.widget<TextField>(
        find.byKey(const Key('height_feet_input')),
      );
      expect(feet.controller?.text, isEmpty);
      final inches = tester.widget<TextField>(
        find.byKey(const Key('height_inches_input')),
      );
      expect(inches.controller?.text, isEmpty);
    });
  });

  group('StepUnitsHeight metric errors', () {
    testWidgets(
      'shows error for invalid metric height, then clears on typing',
      (tester) async {
        await tester.pumpWidget(
          buildApp(
            StepUnitsHeight(
              initialUnit: MeasurementUnit.metric,
              initialHeightCm: null,
              isCurrentPage: true,
              onNext: (_, _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final (errorText, next) = l10nStrings(tester);

        await tester.enterText(find.byKey(const Key('height_cm_input')), 'abc');
        await tester.tap(find.text(next));
        await tester.pumpAndSettle();

        expect(find.text(errorText), findsWidgets);

        await tester.enterText(find.byKey(const Key('height_cm_input')), '180');
        await tester.pumpAndSettle();
        expect(find.text(errorText), findsNothing);
      },
    );

    testWidgets('rejects metric height outside the allowed range', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final (errorText, next) = l10nStrings(tester);

      await tester.enterText(find.byKey(const Key('height_cm_input')), '300');
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();

      expect(find.text(errorText), findsWidgets);
    });

    testWidgets('submitting the metric field validates the form', (
      tester,
    ) async {
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 170.0,
            isCurrentPage: true,
            onNext: (unit, height) => selectedHeight = height,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(selectedHeight, 170.0);
    });
    testWidgets('submitting the imperial feet or inches field validates the '
        'form', (tester) async {
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.imperial,
            initialHeightCm: null,
            isCurrentPage: true,
            onNext: (unit, height) => selectedHeight = height,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final (errorText, _) = l10nStrings(tester);

      // Submitting with 1 ft (which is < 50cm) should fail
      await tester.enterText(find.byKey(const Key('height_feet_input')), '1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text(errorText), findsWidgets);
      expect(selectedHeight, isNull);

      // Submitting with 5 ft 9 inches validates successfully.
      await tester.enterText(find.byKey(const Key('height_feet_input')), '5');
      await tester.enterText(find.byKey(const Key('height_inches_input')), '9');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(selectedHeight, closeTo(175.26, 0.01));
      expect(find.text(errorText), findsNothing);
    });
  });

  group('StepUnitsHeight focus lifecycle', () {
    testWidgets('requests focus when the step becomes the current page', (
      tester,
    ) async {
      Widget build({required bool isCurrentPage}) {
        return buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 170.0,
            isCurrentPage: isCurrentPage,
            onNext: (_, _) {},
          ),
        );
      }

      await tester.pumpWidget(build(isCurrentPage: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fieldFocused(tester, const Key('height_cm_input')), isFalse);

      await tester.pumpWidget(build(isCurrentPage: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fieldFocused(tester, const Key('height_cm_input')), isTrue);
    });
  });
}
