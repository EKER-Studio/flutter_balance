import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/bmi_status_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildSubject({
    required List<WeightEntry> entries,
    double? heightCm,
    MeasurementUnit unit = MeasurementUnit.metric,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BmiStatusCard(
            entries: entries,
            heightCm: heightCm,
            unit: unit,
          ),
        ),
      ),
    );
  }

  group('BmiStatusCard', () {
    testWidgets('renders prompt to set height when heightCm is null', (
      tester,
    ) async {
      final entries = [
        WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime.now()),
      ];

      await tester.pumpWidget(buildSubject(entries: entries, heightCm: null));
      await tester.pumpAndSettle();

      expect(find.text('BMI'), findsOneWidget);
      expect(
        find.text(
          'Set your height in Settings to see BMI analysis and your healthy weight range.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state message when entries is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(entries: [], heightCm: 180.0));
      await tester.pumpAndSettle();

      expect(find.text('BMI'), findsOneWidget);
      expect(
        find.textContaining('Your statistics will appear here'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders BMI score, category badge, and healthy weight range for overweight entry',
      (tester) async {
        // Height 180 cm (1.8 m), Weight 90 kg -> BMI = 90 / 3.24 = 27.78 (Overweight)
        // Healthy weight range: 18.5 * 3.24 = 59.94 to 24.9 * 3.24 = 80.68 -> ~59.9 – 80.7 kg
        // Distance to normal: 90 - 80.68 = 9.3 kg
        final entries = [
          WeightEntry(id: 1, weightKg: 90.0, dateTime: DateTime.now()),
        ];

        await tester.pumpWidget(
          buildSubject(entries: entries, heightCm: 180.0),
        );
        await tester.pumpAndSettle();

        expect(find.text('27.8'), findsOneWidget);
        expect(find.text('Overweight'), findsOneWidget);
        expect(
          find.textContaining('Healthy weight: 59.9 kg – 80.7 kg'),
          findsOneWidget,
        );
        expect(find.textContaining('9.3 kg to normal BMI'), findsOneWidget);
        expect(find.text('18.5 – 24.9'), findsOneWidget);
      },
    );

    testWidgets('renders in healthy range indicator when BMI is normal', (
      tester,
    ) async {
      // Height 180 cm, Weight 72 kg -> BMI = 72 / 3.24 = 22.2 (Normal)
      final entries = [
        WeightEntry(id: 1, weightKg: 72.0, dateTime: DateTime.now()),
      ];

      await tester.pumpWidget(buildSubject(entries: entries, heightCm: 180.0));
      await tester.pumpAndSettle();

      expect(find.text('22.2'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('In healthy BMI range'), findsOneWidget);
    });

    testWidgets('tapping info button opens BmiLegendDialog', (tester) async {
      final entries = [
        WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime.now()),
      ];

      await tester.pumpWidget(buildSubject(entries: entries, heightCm: 180.0));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.byType(BmiLegendDialog), findsOneWidget);
    });
  });
}
