import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/presentation/widgets/components/date_time_picker_row.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? dateTimeError,
    VoidCallback? onPickDate,
    VoidCallback? onPickTime,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DateTimePickerRow(
            selectedDate: selectedDate ?? DateTime(2026, 5, 20),
            selectedTime: selectedTime ?? const TimeOfDay(hour: 10, minute: 15),
            dateTimeError: dateTimeError,
            onPickDate: onPickDate ?? () {},
            onPickTime: onPickTime ?? () {},
          ),
        ),
      ),
    );
  }

  group('DateTimePickerRow', () {
    testWidgets('renders date and time fields with formatted text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.access_time_outlined), findsOneWidget);
      expect(find.text('5/20/2026'), findsOneWidget);
      expect(find.text('10:15 AM'), findsOneWidget);
      expect(find.byKey(const Key('date_time_error_text')), findsNothing);
    });

    testWidgets('triggers onPickDate callback when date field tapped', (tester) async {
      var dateTapped = false;
      await tester.pumpWidget(
        buildTestWidget(onPickDate: () => dateTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      expect(dateTapped, isTrue);
    });

    testWidgets('triggers onPickTime callback when time field tapped', (tester) async {
      var timeTapped = false;
      await tester.pumpWidget(
        buildTestWidget(onPickTime: () => timeTapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.access_time_outlined));
      expect(timeTapped, isTrue);
    });

    testWidgets('displays error banner when dateTimeError is present', (tester) async {
      const errorMsg = 'Future date not allowed';
      await tester.pumpWidget(buildTestWidget(dateTimeError: errorMsg));
      await tester.pumpAndSettle();

      expect(find.text(errorMsg), findsOneWidget);
    });
  });
}
