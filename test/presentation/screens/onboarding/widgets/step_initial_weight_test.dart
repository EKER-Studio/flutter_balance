import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_initial_weight.dart';

void main() {
  Widget buildTestWidget({
    required MeasurementUnit unit,
    required void Function(double, DateTime) onComplete,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StepInitialWeight(
          unit: unit,
          onComplete: onComplete,
        ),
      ),
    );
  }

  group('StepInitialWeight', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (_, _) {},
      ));
      
      await tester.pumpAndSettle();

      expect(find.text('Initial Weight'), findsOneWidget);
      expect(find.text('Log your starting weight measurement to begin tracking.'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Current Weight (kg)'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows validation error when empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (_, _) {},
      ));
      
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Initial weight is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid weight (<0)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (_, _) {},
      ));
      
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '-5');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a valid weight (> 0)'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid weight (>500)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (_, _) {},
      ));
      
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '600');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('Please enter a valid weight (> 0)'), findsOneWidget);
    });

    testWidgets('calls onComplete with valid metric weight', (tester) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (weight, time) {
          resultWeight = weight;
          resultTime = time;
        },
      ));
      
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '75.5');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(resultWeight, 75.5);
      expect(resultTime, isNotNull);
    });

    testWidgets('calls onComplete with valid imperial weight converted to kg', (tester) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.imperial,
        onComplete: (weight, time) {
          resultWeight = weight;
          resultTime = time;
        },
      ));
      
      await tester.pumpAndSettle();

      expect(find.text('Current Weight (lbs)'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '150.0');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // 150 lbs is roughly 68.0388 kg
      expect(resultWeight, closeTo(68.0388, 0.01));
      expect(resultTime, isNotNull);
    });

    testWidgets('can pick a new date and time', (tester) async {
      double? resultWeight;
      DateTime? resultTime;

      await tester.pumpWidget(buildTestWidget(
        unit: MeasurementUnit.metric,
        onComplete: (weight, time) {
          resultWeight = weight;
          resultTime = time;
        },
      ));
      
      await tester.pumpAndSettle();

      // Tap on the date picker button
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Tap 'OK' on date picker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap 'OK' on time picker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '80.0');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(resultWeight, 80.0);
      expect(resultTime, isNotNull);
    });
  });
}
