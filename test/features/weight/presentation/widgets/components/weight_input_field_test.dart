import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/presentation/widgets/components/weight_input_field.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required TextEditingController controller,
    MeasurementUnit unit = MeasurementUnit.metric,
    String? weightError,
    ValueChanged<String>? onChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WeightInputField(
            controller: controller,
            unit: unit,
            weightError: weightError,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('WeightInputField', () {
    testWidgets('renders metric label when unit is metric', (tester) async {
      final controller = TextEditingController(text: '70.5');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestWidget(controller: controller, unit: MeasurementUnit.metric),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weight (kg)'), findsOneWidget);
      expect(find.text('70.5'), findsOneWidget);
    });

    testWidgets('renders imperial label when unit is imperial', (tester) async {
      final controller = TextEditingController(text: '155.0');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestWidget(controller: controller, unit: MeasurementUnit.imperial),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weight in lb'), findsOneWidget);
      expect(find.text('155.0'), findsOneWidget);
    });

    testWidgets('calls onChanged when user inputs text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? updatedText;

      await tester.pumpWidget(
        buildTestWidget(
          controller: controller,
          onChanged: (val) => updatedText = val,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '82.3');
      expect(updatedText, equals('82.3'));
    });

    testWidgets('displays error text when weightError is provided', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      const errorMsg = 'Please enter a valid weight';

      await tester.pumpWidget(
        buildTestWidget(controller: controller, weightError: errorMsg),
      );
      await tester.pumpAndSettle();

      expect(find.text(errorMsg), findsOneWidget);
    });
  });
}
