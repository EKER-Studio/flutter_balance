import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_csv_import.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Test double for [CsvImportService] that returns canned results.
class FakeCsvImportService extends CsvImportService {
  FakeCsvImportService({this.results = const [], this.error, this.throwOnCall});

  /// Results returned on successive [pickAndImport] calls, in order.
  final List<CsvImportResult?> results;

  /// When set, [pickAndImport] throws this error on the [throwOnCall]-th call
  /// (or on every call when [throwOnCall] is null).
  final Object? error;

  /// 1-based call index on which [error] is thrown.
  final int? throwOnCall;

  int calls = 0;

  @override
  Future<CsvImportResult?> pickAndImport() async {
    calls++;
    if (error != null && (throwOnCall == null || throwOnCall == calls)) {
      throw error!;
    }
    if (results.isEmpty) return null;
    return results[(calls - 1).clamp(0, results.length - 1)];
  }
}

void main() {
  final sampleEntries = [
    WeightEntry(weightKg: 75.2, dateTime: DateTime(2024, 1, 15, 7, 30)),
    WeightEntry(weightKg: 75.0, dateTime: DateTime(2024, 1, 16, 7, 30)),
  ];

  Widget buildSubject({
    required CsvImportService service,
    ValueChanged<List<WeightEntry>>? onFileImported,
    VoidCallback? onSkipped,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StepCsvImport(
          importService: service,
          onFileImported: onFileImported ?? (_) {},
          onSkipped: onSkipped ?? () {},
        ),
      ),
    );
  }

  group('StepCsvImport', () {
    testWidgets('renders idle state with title, import tile, and next button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(service: FakeCsvImportService()));
      await tester.pumpAndSettle();

      expect(find.text('Your Past History'), findsOneWidget);
      expect(
        find.text(
          'Coming from another app? Import your CSV file to continue '
          'without losing data.',
        ),
        findsOneWidget,
      );
      expect(find.text('Import CSV file'), findsOneWidget);
      expect(find.text('Add history from your old app'), findsOneWidget);
      expect(find.byKey(const Key('csv_import_tile')), findsOneWidget);
      expect(find.text('Required column format:'), findsOneWidget);
      expect(
        find.text(
          'ID, Date, Time (opt), Weight (kg), Note\n(or: Data; Czas; Waga (kg))',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('csv_import_next_button')), findsOneWidget);
    });

    testWidgets('invokes onSkipped when the next button is pressed', (
      tester,
    ) async {
      var skipped = false;
      await tester.pumpWidget(
        buildSubject(
          service: FakeCsvImportService(),
          onSkipped: () => skipped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('csv_import_next_button')));
      await tester.pumpAndSettle();

      expect(skipped, isTrue);
    });

    testWidgets('shows the loading indicator while parsing', (tester) async {
      final completer = Completer<CsvImportResult?>();
      final service = _PendingImportService(completer);
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('csv_import_tile')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing CSV file...'), findsOneWidget);

      completer.complete((
        validEntries: sampleEntries,
        skippedRowCount: 0,
        earliestDate: null,
        latestDate: null,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'shows success with imported count and invokes onFileImported on continue',
      (tester) async {
        List<WeightEntry>? imported;
        final service = FakeCsvImportService(
          results: [
            (
              validEntries: sampleEntries,
              skippedRowCount: 2,
              earliestDate: null,
              latestDate: null,
            ),
          ],
        );
        await tester.pumpWidget(
          buildSubject(
            service: service,
            onFileImported: (entries) => imported = entries,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('csv_import_tile')));
        await tester.pumpAndSettle();

        expect(find.text('Imported 2 entries'), findsOneWidget);
        expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
        expect(
          find.byKey(const Key('csv_import_continue_button')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('csv_import_continue_button')));
        await tester.pumpAndSettle();

        expect(imported, sampleEntries);
      },
    );

    testWidgets('shows friendly error and retries after a parse failure', (
      tester,
    ) async {
      final service = FakeCsvImportService(
        results: [
          (
            validEntries: sampleEntries,
            skippedRowCount: 0,
            earliestDate: null,
            latestDate: null,
          ),
        ],
        error: FormatException('missing columns'),
        throwOnCall: 1,
      );
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('csv_import_tile')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "We couldn't read this file. Make sure it is a valid CSV file with "
          'date and weight columns.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('csv_import_retry_button')), findsOneWidget);

      // Subsequent retries succeed as the fake throws only once.
      await tester.tap(find.byKey(const Key('csv_import_retry_button')));
      await tester.pumpAndSettle();

      expect(find.text('Imported 2 entries'), findsOneWidget);
    });

    testWidgets('shows no-data message when the file has no valid entries', (
      tester,
    ) async {
      final service = FakeCsvImportService(
        results: [
          (
            validEntries: <WeightEntry>[],
            skippedRowCount: 5,
            earliestDate: null,
            latestDate: null,
          ),
        ],
      );
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('csv_import_tile')));
      await tester.pumpAndSettle();

      expect(
        find.text('No valid weight entries found in the imported file.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('csv_import_retry_button')), findsOneWidget);
    });

    testWidgets('stays idle when the file picker is canceled', (tester) async {
      final service = FakeCsvImportService(results: [null]);
      await tester.pumpWidget(buildSubject(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('csv_import_tile')));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('csv_import_tile')), findsOneWidget);
      expect(find.byKey(const Key('csv_import_next_button')), findsOneWidget);
    });
  });
}

/// Test double whose [pickAndImport] completes only when [completer] does.
class _PendingImportService extends CsvImportService {
  _PendingImportService(this.completer);

  final Completer<CsvImportResult?> completer;

  @override
  Future<CsvImportResult?> pickAndImport() => completer.future;
}
