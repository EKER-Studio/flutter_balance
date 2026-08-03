import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_initial_weight.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_target_weight.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_units_height.dart';

void main() {
  group('StepUnitsHeight Widget Tests', () {
    testWidgets('renders unit segmented button and metric height input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepUnitsHeight(
              initialUnit: MeasurementUnit.metric,
              initialHeightCm: 175.0,
              onNext: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('Units & Height'), findsOneWidget);
      expect(find.text('Metric (kg / cm)'), findsOneWidget);
      expect(find.text('Imperial (lbs / ft-in)'), findsOneWidget);
      expect(find.byKey(const Key('height_cm_input')), findsOneWidget);
    });

    testWidgets('switches to imperial inputs when imperial segment selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepUnitsHeight(
              initialUnit: MeasurementUnit.metric,
              initialHeightCm: 175.0,
              onNext: (_, _) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Imperial (lbs / ft-in)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('height_feet_input')), findsOneWidget);
      expect(find.byKey(const Key('height_inches_input')), findsOneWidget);
    });

    testWidgets('invokes onNext with valid metric height', (tester) async {
      MeasurementUnit? selectedUnit;
      double? selectedHeight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepUnitsHeight(
              initialUnit: MeasurementUnit.metric,
              initialHeightCm: 180.0,
              onNext: (unit, height) {
                selectedUnit = unit;
                selectedHeight = height;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(selectedUnit, MeasurementUnit.metric);
      expect(selectedHeight, 180.0);
    });
  });

  group('StepTargetWeight Widget Tests', () {
    testWidgets('renders target weight input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepTargetWeight(
              unit: MeasurementUnit.metric,
              onNext: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Target Weight'), findsOneWidget);
      expect(find.byKey(const Key('target_weight_input')), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('calls onNext(null) when Skip pressed', (tester) async {
      double? result;
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepTargetWeight(
              unit: MeasurementUnit.metric,
              onNext: (val) {
                called = true;
                result = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });

    testWidgets('calls onNext with parsed target weight when Next pressed', (tester) async {
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepTargetWeight(
              unit: MeasurementUnit.metric,
              onNext: (val) {
                result = val;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('target_weight_input')), '75.5');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(result, closeTo(75.5, 0.01));
    });
  });

  group('StepInitialWeight Widget Tests', () {
    testWidgets('renders initial weight input and complete button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInitialWeight(
              unit: MeasurementUnit.metric,
              onComplete: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('Initial Weight'), findsOneWidget);
      expect(find.byKey(const Key('initial_weight_input')), findsOneWidget);
      expect(find.text('Complete Setup'), findsOneWidget);
    });

    testWidgets('shows validation error if initial weight is empty on submit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInitialWeight(
              unit: MeasurementUnit.metric,
              onComplete: (_, _) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Initial weight is required'), findsOneWidget);
    });

    testWidgets('calls onComplete when valid weight is entered', (tester) async {
      double? weightResult;
      DateTime? timeResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepInitialWeight(
              unit: MeasurementUnit.metric,
              onComplete: (w, t) {
                weightResult = w;
                timeResult = t;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('initial_weight_input')), '82.3');
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(weightResult, closeTo(82.3, 0.01));
      expect(timeResult, isNotNull);
    });
  });
}
