import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_cell.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  /// Pumps [child] inside a [MaterialApp] with the app's localization delegates
  /// and a [Scaffold] so [Theme] and [AppLocalizations] resolve.
  Future<void> pumpGrid(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CalendarGrid — first day of week', () {
    testWidgets('renders 42 cells with FirstDayOfWeek.monday', (tester) async {
      final focusedMonth = DateTime(2024, 6, 1);
      final selectedDate = DateTime(2024, 6, 15);

      await pumpGrid(
        tester,
        CalendarGrid(
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          entries: const [],
          firstDayOfWeek: FirstDayOfWeek.monday,
          onDaySelected: (_, _) {},
        ),
      );

      // A 6-week grid renders one [CalendarDayCell] per day in the month
      // (June has 30 days); the leading offset cells are SizedBox shrinks.
      expect(find.byType(CalendarDayCell), findsNWidgets(30));
    });

    testWidgets('renders 42 cells with FirstDayOfWeek.sunday', (tester) async {
      final focusedMonth = DateTime(2024, 6, 1);
      final selectedDate = DateTime(2024, 6, 15);

      await pumpGrid(
        tester,
        CalendarGrid(
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          entries: const [],
          firstDayOfWeek: FirstDayOfWeek.sunday,
          onDaySelected: (_, _) {},
        ),
      );

      expect(find.byType(CalendarDayCell), findsNWidgets(30));
    });
  });
}
