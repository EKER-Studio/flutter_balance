import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

void main() {
  group('WeightState Subclass & Props Tests', () {
    final entry1 = WeightEntry(
      id: 1,
      weightKg: 75.0,
      dateTime: DateTime(2026, 6, 1),
    );

    test('WeightInitial initializes with standard defaults', () {
      const state = WeightInitial();
      expect(state.heightCm, isNull);
      expect(state.timePeriod, TimePeriod.week);
      expect(state.entries, isEmpty);
      expect(state.filteredEntries, isEmpty);
    });

    test('WeightLoading maintains height, period, and entries', () {
      final state = WeightLoading(
        heightCm: 180.0,
        timePeriod: TimePeriod.month,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      expect(state.heightCm, 180.0);
      expect(state.timePeriod, TimePeriod.month);
      expect(state.entries, [entry1]);
    });

    test('WeightLoaded equality and props hold across identical instances', () {
      final state1 = WeightLoaded(
        heightCm: 175.0,
        timePeriod: TimePeriod.month,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      final state2 = WeightLoaded(
        heightCm: 175.0,
        timePeriod: TimePeriod.month,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
    });

    test('WeightError contains typed errorType and last-known entries', () {
      final state = WeightError(
        errorType: WeightErrorType.readFailed,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      expect(state.errorType, WeightErrorType.readFailed);
      expect(state.entries, [entry1]);
      expect(state.props, contains(WeightErrorType.readFailed));
    });

    test('CsvAnalysisInProgress and CsvAnalysisReady state transitions', () {
      final inProgress = CsvAnalysisInProgress(
        entries: [entry1],
        filteredEntries: [entry1],
      );
      expect(inProgress.entries, [entry1]);

      const CsvImportAnalysis analysis = (
        validEntries: [],
        skippedRowCount: 0,
        earliestDate: null,
        latestDate: null,
      );

      final ready = CsvAnalysisReady(
        entries: [entry1],
        filteredEntries: [entry1],
        analysis: analysis,
      );

      expect(ready.analysis, analysis);
      expect(ready.props, contains(analysis));
    });

    test('WeightImportSuccess reflects importedCount in props', () {
      final success = WeightImportSuccess(
        importedCount: 5,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      expect(success.importedCount, 5);
      expect(success.props, contains(5));
    });

    test('CsvAnalysisError reflects CsvErrorType in props', () {
      final error = CsvAnalysisError(
        errorType: CsvErrorType.noEntries,
        entries: [entry1],
        filteredEntries: [entry1],
      );

      expect(error.errorType, CsvErrorType.noEntries);
      expect(error.props, contains(CsvErrorType.noEntries));
    });
  });
}
