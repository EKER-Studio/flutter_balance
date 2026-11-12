import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/calendar/presentation/widgets/sections/calendar_month_card.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_grid.dart';
import 'package:balance/features/settings/presentation/bloc/first_day_of_week.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('CalendarMonthCard', () {
    late DateTime focusedMonth;
    late DateTime selectedDate;

    setUp(() {
      focusedMonth = DateTime(2026, 7, 1);
      selectedDate = DateTime(2026, 7, 15);
    });

    Widget createTestWidget({
      List<WeightEntry> entries = const [],
      double? targetWeight,
      FirstDayOfWeek firstDayOfWeek = FirstDayOfWeek.system,
      WeightGoalMode goalMode = WeightGoalMode.lose,
      VoidCallback? onPreviousMonth,
      VoidCallback? onNextMonth,
      ValueChanged<DateTime>? onDaySelected,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CalendarMonthCard(
            focusedMonth: focusedMonth,
            selectedDate: selectedDate,
            entries: entries,
            targetWeight: targetWeight,
            firstDayOfWeek: firstDayOfWeek,
            goalMode: goalMode,
            onPreviousMonth: onPreviousMonth ?? () {},
            onNextMonth: onNextMonth ?? () {},
            onDaySelected: onDaySelected ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('renders month header, weekday names, and grid', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CalendarMonthCard), findsOneWidget);
      expect(find.byType(CalendarGrid), findsOneWidget);
      // The month header shows the focused year.
      expect(find.textContaining('2026'), findsOneWidget);
      // Day numbers are rendered by the grid.
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('delegates a tapped day to onDaySelected', (tester) async {
      DateTime? selected;

      await tester.pumpWidget(
        createTestWidget(onDaySelected: (date) => selected = date),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(selected, DateTime(2026, 7, 15));
    });
  });
}
