import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/widgets/components/pace_window_selection_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  group('PaceWindowSelectionDialog', () {
    testWidgets(
      'renders all pace window choices and calls onSelected on choice',
      (tester) async {
        int? selectedWindow;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    PaceWindowSelectionDialog.show(
                      context,
                      currentDays: 30,
                      onSelected: (days) => selectedWindow = days,
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

        expect(find.text('Pace calculation window'), findsOneWidget);
        expect(find.text('Last 7 days'), findsOneWidget);
        expect(find.text('Last 14 days'), findsOneWidget);
        expect(find.text('Last 30 days (default)'), findsOneWidget);
        expect(find.text('Last 60 days'), findsOneWidget);
        expect(find.text('Last 90 days'), findsOneWidget);

        await tester.tap(find.text('Last 14 days'));
        await tester.pumpAndSettle();

        expect(selectedWindow, equals(14));
        expect(find.byType(PaceWindowSelectionDialog), findsNothing);
      },
    );
  });
}
