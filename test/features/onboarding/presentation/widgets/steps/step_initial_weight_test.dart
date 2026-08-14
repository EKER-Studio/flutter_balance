import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';

void main() {
  Widget buildTestWidget({
    required MeasurementUnit unit,
    required void Function(double, DateTime) onNext,
    double? initialWeightKg,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StepInitialWeight(
          unit: unit,
          initialWeightKg: initialWeightKg,
          onNext: onNext,
        ),
      ),
    );
  }

  group('StepInitialWeight', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
      );

      await tester.pumpAndSettle();

      expect(find.text('Your Starting Point'), findsOneWidget);
      expect(
        find.text(
          'Log your current weight. This is your first step towards reaching your goal.',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Current Weight (kg)'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Next button is disabled if empty', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
      );

      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows validation error for invalid weight (<0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '-5');
      await tester.pump();

      expect(
        find.text('Please enter a valid positive number.'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error for invalid weight (>500)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '600');
      await tester.pump();

      expect(
        find.text('Please enter a valid positive number.'),
        findsOneWidget,
      );
    });

    testWidgets('calls onNext with valid metric weight', (tester) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.metric,
          onNext: (weight, time) {
            resultWeight = weight;
            resultTime = time;
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '75.5');
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(resultWeight, 75.5);
      expect(resultTime, isNotNull);
    });

    testWidgets('calls onNext with valid imperial weight converted to kg', (
      tester,
    ) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.imperial,
          onNext: (weight, time) {
            resultWeight = weight;
            resultTime = time;
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '150.0');
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 150 lbs is roughly 68.0388 kg
      expect(resultWeight, closeTo(68.0388, 0.01));
      expect(resultTime, isNotNull);
    });

    testWidgets('calls onNext with comma-separated weight', (tester) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.metric,
          onNext: (weight, time) {
            resultWeight = weight;
            resultTime = time;
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '75,5');
      await tester.pumpAndSettle();

      final nextButton = find.text('Next');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(resultWeight, closeTo(75.5, 0.01));
      expect(resultTime, isNotNull);
    });

    testWidgets('pre-fills the input with the imported weight in kg', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.metric,
          initialWeightKg: 86.0,
          onNext: (_, _) {},
        ),
      );

      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '86.0');

      // Enable Next immediately with the pre-filled value.
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('pre-fills the input converted to lbs for imperial units', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.imperial,
          initialWeightKg: 68.0,
          onNext: (_, _) {},
        ),
      );

      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      // 68 kg is roughly 149.9 lbs.
      expect(field.controller!.text, '149.9');
    });

    testWidgets('ignores out-of-range imported weights and stays blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          unit: MeasurementUnit.metric,
          initialWeightKg: 900,
          onNext: (_, _) {},
        ),
      );

      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });
  });
  testWidgets('entering whitespace shows the required error', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(find.text('Initial weight is required'), findsOneWidget);
  });

  testWidgets('submitting via keyboard action triggers onNext', (tester) async {
    double? resultWeight;
    await tester.pumpWidget(
      buildTestWidget(
        unit: MeasurementUnit.metric,
        onNext: (weight, _) {
          resultWeight = weight;
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '80');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(resultWeight, 80.0);
  });

  testWidgets('canceling the date picker keeps the selected timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
    );

    await tester.pumpAndSettle();
    final labelBefore = tester
        .widget<Text>(find.textContaining(', ').first)
        .data;

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final labelAfter = tester
        .widget<Text>(find.textContaining(', ').first)
        .data;
    expect(labelAfter, labelBefore);
  });

  testWidgets('canceling the time picker keeps the selected timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(unit: MeasurementUnit.metric, onNext: (_, _) {}),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('OK'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('selecting a date and time updates the timestamp label', (
    tester,
  ) async {
    DateTime? resultTime;
    await tester.pumpWidget(
      buildTestWidget(
        unit: MeasurementUnit.metric,
        onNext: (_, time) {
          resultTime = time;
        },
      ),
    );

    await tester.pumpAndSettle();

    final labelFinder = find.descendant(
      of: find.byType(OutlinedButton),
      matching: find.byType(Text),
    );
    final labelBefore = tester.widget<Text>(labelFinder).data;

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final labelAfter = tester.widget<Text>(labelFinder).data;
    expect(labelAfter, isNot(labelBefore));

    await tester.enterText(find.byType(TextField), '70');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(resultTime, isNotNull);
  });
}
