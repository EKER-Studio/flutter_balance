import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/widgets/height_dialog.dart';

void main() {
  Widget buildTestWidget(double? initialValue) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: HeightDialog(currentValue: initialValue)),
    );
  }

  group('HeightDialog', () {
    testWidgets('renders with initial value', (tester) async {
      await tester.pumpWidget(buildTestWidget(175.0));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      expect(tester.widget<TextField>(textField).controller?.text, '175');
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
  });
}
