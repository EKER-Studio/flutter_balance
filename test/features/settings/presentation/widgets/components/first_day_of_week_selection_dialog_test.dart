import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/settings/presentation/widgets/components/first_day_of_week_selection_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  group('FirstDayOfWeekSelectionDialog', () {
    testWidgets(
      'renders all first-day-of-week choices and calls onSelected on choice',
      (tester) async {
        FirstDayOfWeek? selected;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    FirstDayOfWeekSelectionDialog.show(
                      context,
                      currentFirstDay: FirstDayOfWeek.system,
                      onSelected: (mode) => selected = mode,
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

        expect(find.text('First day of week'), findsOneWidget);
        expect(find.text('System default'), findsOneWidget);
        expect(find.text('Monday'), findsOneWidget);
        expect(find.text('Sunday'), findsOneWidget);

        await tester.tap(find.text('Monday'));
        await tester.pumpAndSettle();

        expect(selected, equals(FirstDayOfWeek.monday));
        expect(find.byType(FirstDayOfWeekSelectionDialog), findsNothing);
      },
    );

    testWidgets('reflects the currently selected first day of week', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  FirstDayOfWeekSelectionDialog.show(
                    context,
                    currentFirstDay: FirstDayOfWeek.sunday,
                    onSelected: (_) {},
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

      final radioGroup = tester.widget<RadioGroup<FirstDayOfWeek>>(
        find.byType(RadioGroup<FirstDayOfWeek>),
      );
      expect(radioGroup.groupValue, equals(FirstDayOfWeek.sunday));
    });

    testWidgets(
      'selecting a non-current choice invokes onSelected and dismisses',
      (tester) async {
        FirstDayOfWeek? selected;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    FirstDayOfWeekSelectionDialog.show(
                      context,
                      currentFirstDay: FirstDayOfWeek.monday,
                      onSelected: (mode) => selected = mode,
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

        await tester.tap(find.text('System default'));
        await tester.pumpAndSettle();

        expect(selected, equals(FirstDayOfWeek.system));
        expect(find.byType(FirstDayOfWeekSelectionDialog), findsNothing);
      },
    );
  });
}
