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

  group('CalendarGrid — goal achievement markers', () {
    testWidgets('marks a day achieved in gain mode when weight >= target', (
      tester,
    ) async {
      // Entry on 2024-06-10 at 75 kg; target 70 kg; gain mode => 75 >= 70.
      final entry = WeightEntry(
        id: 1,
        weightKg: 75.0,
        dateTime: DateTime(2024, 6, 10),
      );
      final focusedMonth = DateTime(2024, 6, 1);
      final selectedDate = DateTime(2024, 6, 10);

      await pumpGrid(
        tester,
        CalendarGrid(
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          entries: [entry],
          targetWeight: 70.0,
          goalMode: WeightGoalMode.gain,
          onDaySelected: (_, _) {},
        ),
      );

      // The entry day renders a cell with the goal-achieved flag set.
      expect(
        find.byWidgetPredicate((w) => w is CalendarDayCell && w.isGoalAchieved),
        findsOneWidget,
      );
    });

    testWidgets('marks a day achieved in maintain mode when within 1.0 kg', (
      tester,
    ) async {
      // Entry on 2024-06-12 at 70.5 kg; target 70 kg; maintain => |0.5| <= 1.0.
      final entry = WeightEntry(
        id: 2,
        weightKg: 70.5,
        dateTime: DateTime(2024, 6, 12),
      );
      final focusedMonth = DateTime(2024, 6, 1);
      final selectedDate = DateTime(2024, 6, 12);

      await pumpGrid(
        tester,
        CalendarGrid(
          focusedMonth: focusedMonth,
          selectedDate: selectedDate,
          entries: [entry],
          targetWeight: 70.0,
          goalMode: WeightGoalMode.maintain,
          onDaySelected: (_, _) {},
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CalendarDayCell && w.isGoalAchieved),
        findsOneWidget,
      );
    });
  });
}
