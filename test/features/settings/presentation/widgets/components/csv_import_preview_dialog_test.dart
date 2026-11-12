import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/widgets/components/csv_import_preview_dialog.dart';
import 'package:balance/features/weight/domain/entities/csv_import_analysis.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('CsvImportPreviewDialog', () {
    Widget createTestWidget({
      required CsvImportAnalysis analysis,
      void Function(bool result)? onShown,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await CsvImportPreviewDialog.show(
                  context,
                  analysis: analysis,
                );
                onShown?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
    }

    testWidgets('returns true when the user confirms the import', (
      tester,
    ) async {
      bool? returned;
      final analysis = (
        validEntries: [
          WeightEntry(weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ],
        skippedRowCount: 0,
        earliestDate: DateTime(2026, 1, 1),
        latestDate: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        createTestWidget(
          analysis: analysis,
          onShown: (result) => returned = result,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Import Preview'), findsOneWidget);
      expect(find.text('Confirm import'), findsOneWidget);

      await tester.tap(find.text('Confirm import'));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
    });

    testWidgets('returns false when the user cancels the import', (
      tester,
    ) async {
      bool? returned;
      final analysis = (
        validEntries: [
          WeightEntry(weightKg: 70.0, dateTime: DateTime(2026, 1, 1)),
        ],
        skippedRowCount: 0,
        earliestDate: DateTime(2026, 1, 1),
        latestDate: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        createTestWidget(
          analysis: analysis,
          onShown: (result) => returned = result,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returned, isFalse);
    });
  });
}
