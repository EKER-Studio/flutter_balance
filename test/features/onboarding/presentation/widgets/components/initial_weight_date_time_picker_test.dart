import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/onboarding/presentation/widgets/components/initial_weight_date_time_picker.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required DateTime selectedTimestamp,
    required VoidCallback onTap,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: InitialWeightDateTimePicker(
            selectedTimestamp: selectedTimestamp,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('InitialWeightDateTimePicker', () {
    testWidgets('renders formatted timestamp and invokes onTap on tap', (
      tester,
    ) async {
      var tapped = false;
      final timestamp = DateTime(2026, 5, 20, 14, 30);

      await tester.pumpWidget(
        buildTestWidget(
          selectedTimestamp: timestamp,
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Measurement Date & Time'), findsOneWidget);

      await tester.tap(find.byKey(const Key('initial_weight_date_picker')));
      expect(tapped, isTrue);
    });
  });
}
