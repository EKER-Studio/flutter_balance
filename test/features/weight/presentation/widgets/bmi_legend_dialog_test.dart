import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const BmiLegendDialog(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title and all four BMI category legend rows', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('BMI Categories'), findsOneWidget);

    expect(find.text('Underweight'), findsOneWidget);
    expect(find.text('< 18.5'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('18.5 – 24.9'), findsOneWidget);
    expect(find.text('Overweight'), findsOneWidget);
    expect(find.text('25.0 – 29.9'), findsOneWidget);
    expect(find.text('Obese'), findsOneWidget);
    expect(find.text('≥ 30.0'), findsOneWidget);
  });

  testWidgets('renders a colored swatch per legend row', (tester) async {
    await pumpDialog(tester);

    final swatches = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(BmiLegendDialog),
            matching: find.byType(Container),
          ),
        )
        .where(
          (c) =>
              c.constraints?.maxWidth == 16 && c.constraints?.maxHeight == 16,
        )
        .toList();
    expect(swatches, hasLength(4));

    for (final swatch in swatches) {
      final decoration = swatch.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(decoration.border, isNotNull);
    }
  });

  testWidgets('OK button closes the dialog', (tester) async {
    await pumpDialog(tester);

    expect(find.byType(BmiLegendDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(BmiLegendDialog), findsNothing);
  });
}
