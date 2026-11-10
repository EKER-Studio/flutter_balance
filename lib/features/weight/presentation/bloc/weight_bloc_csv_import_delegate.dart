part of 'weight_bloc.dart';

/// Handles the CSV import events for [WeightBloc]: dry-run analysis of a file
/// and confirmation of the parsed entries.
///
/// Both handlers re-read the bloc's current state through [ctx.getState] so the
/// emitted [WeightState] reflects the latest height and time period.
class _CsvImportDelegate {
  final _WeightBlocContext ctx;

  _CsvImportDelegate(this.ctx);

  /// Reads and parses a CSV file on a background isolate without writing to the
  /// database (dry-run analysis).
  Future<void> onAnalyze(
    AnalyzeCsvFile event,
    Emitter<WeightState> emit,
  ) async {
    final state = ctx.getState();
    final currentEntries = ctx.entriesFromState(state);
    emit(
      CsvAnalysisInProgress(
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: currentEntries,
        filteredEntries: ctx.filterEntries(currentEntries, state.timePeriod),
      ),
    );

    final outcome = await ctx.csvWeightImporter.analyzeFile(event.filePath);
    switch (outcome) {
      case CsvAnalysisSuccess(:final analysis):
        final state = ctx.getState();
        emit(
          CsvAnalysisReady(
            heightCm: state.heightCm,
            timePeriod: state.timePeriod,
            entries: currentEntries,
            filteredEntries: ctx.filterEntries(
              currentEntries,
              state.timePeriod,
            ),
            analysis: analysis,
          ),
        );
      case CsvAnalysisFailure(:final errorType):
        final state = ctx.getState();
        emit(
          CsvAnalysisError(
            errorType: errorType,
            heightCm: state.heightCm,
            timePeriod: state.timePeriod,
            entries: currentEntries,
            filteredEntries: ctx.filterEntries(
              currentEntries,
              state.timePeriod,
            ),
          ),
        );
    }
  }

  Future<void> onConfirm(
    ConfirmCsvImport event,
    Emitter<WeightState> emit,
  ) async {
    final currentEntries = ctx.entriesFromState(ctx.getState());
    try {
      final count = await ctx.csvWeightImporter.confirmImport(
        event.validEntries,
      );

      if (ctx.isHealthSyncEnabled && event.validEntries.isNotEmpty) {
        unawaited(
          Future.forEach(event.validEntries, (entry) => ctx.mirrorWrite(entry)),
        );
      }

      final updatedEntries = await ctx.repository.getAllEntries();
      final state = ctx.getState();
      final filtered = ctx.filterEntries(updatedEntries, state.timePeriod);
      emit(
        WeightImportSuccess(
          importedCount: count,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: updatedEntries,
          filteredEntries: filtered,
        ),
      );
      emit(
        WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: updatedEntries,
          filteredEntries: filtered,
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] ConfirmCsvImport error',
        fatal: false,
      );
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: currentEntries,
          filteredEntries: ctx.filterEntries(currentEntries, state.timePeriod),
        ),
      );
    }
  }
}
