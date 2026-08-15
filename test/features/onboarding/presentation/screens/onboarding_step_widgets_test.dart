import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_target_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('StepUnitsHeight Widget Tests', () {
    testWidgets('renders unit segmented button and metric height input', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 175.0,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      // Flush the delayed initial-focus request scheduled in initState.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Your Basic Details'), findsOneWidget);
      expect(find.text('Metric (kg / cm)'), findsOneWidget);
      expect(find.text('Imperial (lbs / ft-in)'), findsOneWidget);
      expect(find.byKey(const Key('height_cm_input')), findsOneWidget);
    });

    testWidgets('switches to imperial inputs when imperial segment selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 175.0,
            isCurrentPage: true,
            onNext: (_, _) {},
          ),
        ),
      );
      // Flush the delayed initial-focus request scheduled in initState.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Imperial (lbs / ft-in)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('height_feet_input')), findsOneWidget);
      expect(find.byKey(const Key('height_inches_input')), findsOneWidget);
    });

    testWidgets('invokes onNext with valid metric height', (tester) async {
      MeasurementUnit? selectedUnit;
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 180.0,
            isCurrentPage: true,
            onNext: (unit, height) {
              selectedUnit = unit;
              selectedHeight = height;
            },
          ),
        ),
      );
      // Flush the delayed initial-focus request scheduled in initState.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(selectedUnit, MeasurementUnit.metric);
      expect(selectedHeight, 180.0);
    });

    testWidgets('invokes onNext with comma-separated metric height', (
      tester,
    ) async {
      double? selectedHeight;

      await tester.pumpWidget(
        buildApp(
          StepUnitsHeight(
            initialUnit: MeasurementUnit.metric,
            initialHeightCm: 180.0,
            isCurrentPage: true,
            onNext: (unit, height) {
              selectedHeight = height;
            },
          ),
        ),
      );
      // Flush the delayed initial-focus request scheduled in initState.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byKey(const Key('height_cm_input')), '175,5');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(selectedHeight, closeTo(175.5, 0.01));
    });
  });

  group('StepTargetWeight Widget Tests', () {
    testWidgets('renders target weight input', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(unit: MeasurementUnit.metric, onNext: (_) {}),
        ),
      );

      expect(find.text('Your Dream Goal (Optional)'), findsOneWidget);
      expect(find.byKey(const Key('target_weight_input')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('does not show target delta when initial weight is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(unit: MeasurementUnit.metric, onNext: (_) {}),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '70.0',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('target_delta_text')), findsNothing);
    });

    testWidgets('shows live target delta relative to the initial weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            initialWeightKg: 75.5,
            onNext: (_) {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '70',
      );
      await tester.pumpAndSettle();

      expect(find.text('5.5 kg to target'), findsOneWidget);
    });

    testWidgets('shows goal achieved when target is >= initial weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            initialWeightKg: 75.5,
            onNext: (_) {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '80',
      );
      await tester.pumpAndSettle();

      expect(find.text('🏆 Goal achieved!'), findsOneWidget);
    });

    testWidgets('hides target delta when the input becomes invalid', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            initialWeightKg: 75.5,
            onNext: (_) {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '70',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('target_delta_text')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        'abc',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('target_delta_text')), findsNothing);
    });

    testWidgets('calls onNext(null) when Next pressed with empty input', (
      tester,
    ) async {
      double? result;
      bool called = false;

      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            onNext: (val) {
              called = true;
              result = val;
            },
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });

    testWidgets('calls onNext with parsed target weight when Next pressed', (
      tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            onNext: (val) {
              result = val;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '75.5',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(result, closeTo(75.5, 0.01));
    });

    testWidgets('calls onNext with comma-separated target weight', (
      tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            onNext: (val) {
              result = val;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '75,5',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(result, closeTo(75.5, 0.01));
    });

    testWidgets('prefills input with initial target in metric', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            initialTargetWeightKg: 70.0,
            onNext: (_) {},
          ),
        ),
      );

      expect(find.text('70.0'), findsOneWidget);
    });

    testWidgets('prefills input with initial target converted to imperial', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.imperial,
            initialTargetWeightKg: 70.0,
            onNext: (_) {},
          ),
        ),
      );

      expect(find.text('154.3'), findsOneWidget);
    });

    testWidgets('shows target delta in imperial units', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.imperial,
            initialWeightKg: 75.5,
            onNext: (_) {},
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '154.3',
      );
      await tester.pumpAndSettle();

      expect(find.text('12.1 lbs to target'), findsOneWidget);
    });

    testWidgets('calls onNext with imperial input converted to kg', (
      tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.imperial,
            onNext: (val) {
              result = val;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '100',
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(result, closeTo(45.36, 0.01));
    });

    testWidgets('clears inline error when input is emptied', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(unit: MeasurementUnit.metric, onNext: (_) {}),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        'abc',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid positive number.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
            .onPressed,
        isNull,
      );

      await tester.enterText(find.byKey(const Key('target_weight_input')), '');
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid positive number.'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('clears inline error when input becomes valid again', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(unit: MeasurementUnit.metric, onNext: (_) {}),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        'abc',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter a valid positive number.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '70',
      );
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid positive number.'), findsNothing);
    });

    testWidgets('calls onNext when the text field is submitted', (
      tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildApp(
          StepTargetWeight(
            unit: MeasurementUnit.metric,
            onNext: (val) {
              result = val;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('target_weight_input')),
        '75.5',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result, closeTo(75.5, 0.01));
    });
  });

  group('StepInitialWeight Widget Tests', () {
    testWidgets('renders initial weight input and next button', (tester) async {
      await tester.pumpWidget(
        buildApp(
          StepInitialWeight(unit: MeasurementUnit.metric, onNext: (_, _) {}),
        ),
      );

      expect(find.text('Your Starting Point'), findsOneWidget);
      expect(find.byKey(const Key('initial_weight_input')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next button is disabled if initial weight is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          StepInitialWeight(unit: MeasurementUnit.metric, onNext: (_, _) {}),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('calls onNext when valid weight is entered', (tester) async {
      double? weightResult;
      DateTime? timeResult;

      await tester.pumpWidget(
        buildApp(
          StepInitialWeight(
            unit: MeasurementUnit.metric,
            onNext: (w, t) {
              weightResult = w;
              timeResult = t;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('initial_weight_input')),
        '82.3',
      );
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(weightResult, closeTo(82.3, 0.01));
      expect(timeResult, isNotNull);
    });
  });
}
