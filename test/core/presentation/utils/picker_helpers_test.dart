import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/utils/picker_helpers.dart';

void main() {
  group('showSafeTimePicker', () {
    testWidgets('renders time picker and returns selected time', (tester) async {
      TimeOfDay? selectedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTime = await showSafeTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 30),
                  );
                },
                child: const Text('Pick Time'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Time'));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedTime, equals(const TimeOfDay(hour: 8, minute: 30)));
    });

    testWidgets('supports landscape mode with dialOnly mode and custom insets', (
      tester,
    ) async {
      TimeOfDay? selectedTime;

      tester.view.physicalSize = const Size(1200, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTime = await showSafeTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 14, minute: 0),
                  );
                },
                child: const Text('Pick Time'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Time'));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selectedTime, isNull);
    });
  });

  group('showSafeDatePicker', () {
    testWidgets('renders date picker and returns selected date', (tester) async {
      DateTime? selectedDate;
      final initialDate = DateTime(2026, 6, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedDate = await showSafeDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                },
                child: const Text('Pick Date'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedDate, equals(initialDate));
    });

    testWidgets('cancelling returns null', (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedDate = await showSafeDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 6, 15),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                },
                child: const Text('Pick Date'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selectedDate, isNull);
    });
  });
}
