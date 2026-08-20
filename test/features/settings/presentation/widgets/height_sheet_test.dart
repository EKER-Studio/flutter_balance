import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/widgets/height_sheet.dart';
import 'package:balance/core/models/measurement_unit.dart';

void main() {
  Widget buildTestWidget(double? initialValue) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HeightSheet(
          currentValue: initialValue,
          measurementUnit: MeasurementUnit.metric,
        ),
      ),
    );
  }

  /// Opens [HeightSheet] through a real [showModalBottomSheet] route so that
  /// popping resolves the future with the sheet result.
  Future<void> openSheet(
    WidgetTester tester,
    double? initialValue, {
    void Function(double?)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showModalBottomSheet<double>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => HeightSheet(
                      currentValue: initialValue,
                      measurementUnit: MeasurementUnit.metric,
                    ),
                  );
                  onResult?.call(result);
                },
                child: const Text('open sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
  }

  group('HeightSheet', () {
    testWidgets('renders with initial value', (tester) async {
      await tester.pumpWidget(buildTestWidget(175.0));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(find.text('175'), findsOneWidget);
    });

    testWidgets('renders empty when initial value is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(null));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(tester.widget<TextField>(textField).controller?.text, '');
    });

    testWidgets('shows error for invalid height (too small)', (tester) async {
      await tester.pumpWidget(buildTestWidget(null));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '20'); // below min
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Height must be between 50 and 250 cm'), findsOneWidget);
    });

    testWidgets('clears error text on typing', (tester) async {
      await tester.pumpWidget(buildTestWidget(null));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '20');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Height must be between 50 and 250 cm'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '170');
      await tester.pumpAndSettle();

      expect(find.text('Height must be between 50 and 250 cm'), findsNothing);
    });

    testWidgets('shows error when height exceeds the maximum', (tester) async {
      await openSheet(tester, null);

      await tester.enterText(find.byType(TextField), '260');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Height must be between 50 and 250 cm'), findsOneWidget);
    });

    testWidgets('pops with the entered height on save', (tester) async {
      double? result;
      var resolved = false;
      await openSheet(
        tester,
        null,
        onResult: (r) {
          result = r;
          resolved = true;
        },
      );

      await tester.enterText(find.byType(TextField), '170');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, 170.0);
    });

    testWidgets('saves when the keyboard submit action is triggered', (
      tester,
    ) async {
      double? result;
      var resolved = false;
      await openSheet(
        tester,
        null,
        onResult: (r) {
          result = r;
          resolved = true;
        },
      );

      await tester.enterText(find.byType(TextField), '175');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, 175.0);
    });

    testWidgets('cancel closes the dialog without a result', (tester) async {
      var resolved = false;
      await openSheet(tester, null, onResult: (_) => resolved = true);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
    });
  });
}
