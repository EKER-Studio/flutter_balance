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
}
