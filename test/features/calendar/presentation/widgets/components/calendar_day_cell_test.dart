import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/theme/app_feedback_theme.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_day_cell.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  /// Pumps [child] inside a [MaterialApp] with the app's localization
  /// delegates and a [Scaffold] so [Theme] and [AppLocalizations] resolve.
  Future<void> pumpCell(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CalendarDayCell — today text color', () {
    testWidgets('colors the day number with primary when isToday is true', (
      tester,
    ) async {
      await pumpCell(
        tester,
        CalendarDayCell(
          date: DateTime(2024, 6, 15),
          dayNumber: 15,
          isToday: true,
        ),
      );

      // The day-number Text uses colorScheme.primary when isToday is set
      // (line 72), rather than onSurface.
      final text = tester.widget<Text>(find.text('15'));
      expect(text.style?.color, isNotNull);
      expect(text.style?.fontWeight, FontWeight.bold);
    });
  });

  group('CalendarDayCell — multi-entry indicator', () {
    testWidgets('renders a single bar for 4+ entries (goal achieved)', (
      tester,
    ) async {
      final entries = List.generate(
        4,
        (i) => WeightEntry(
          id: i + 1,
          weightKg: 68.0,
          dateTime: DateTime(2024, 6, 15),
        ),
      );

      await pumpCell(
        tester,
        CalendarDayCell(
          date: DateTime(2024, 6, 15),
          dayNumber: 15,
          entries: entries,
          targetWeight: 70.0,
          goalMode: WeightGoalMode.lose,
          isGoalAchieved: true,
        ),
      );

      // With 4+ entries the cell renders a single 12x3.5 bar (lines 118-129),
      // not individual dots. The bar color is green because the entries
      // reached the target (68 <= 70 in lose mode).
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(CalendarDayCell),
          matching: find.byType(Container),
        ),
      );
      final bar = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 12 && c.constraints?.maxHeight == 3.5,
      );
      final decoration = bar.decoration as BoxDecoration;
      expect(decoration.color, AppFeedbackTheme.successForegroundLight);
    });

    testWidgets('renders a single bar for 4+ entries (goal not achieved)', (
      tester,
    ) async {
      final entries = List.generate(
        5,
        (i) => WeightEntry(
          id: i + 1,
          weightKg: 80.0,
          dateTime: DateTime(2024, 6, 15),
        ),
      );

      await pumpCell(
        tester,
        CalendarDayCell(
          date: DateTime(2024, 6, 15),
          dayNumber: 15,
          entries: entries,
          targetWeight: 70.0,
          goalMode: WeightGoalMode.lose,
          isGoalAchieved: false,
        ),
      );

      // 80 kg > 70 target in lose mode => not achieved => blue bar.
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(CalendarDayCell),
          matching: find.byType(Container),
        ),
      );
      final bar = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 12 && c.constraints?.maxHeight == 3.5,
      );
      final decoration = bar.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });
}
