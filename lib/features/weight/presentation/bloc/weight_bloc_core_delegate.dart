part of 'weight_bloc.dart';

/// Handles the core CRUD + chart-filter events for [WeightBloc]:
/// subscribing to the repository watch, updating height, adding / updating /
/// deleting entries, changing the chart filter, refreshing, clearing all data,
/// and bulk-importing entries.
///
/// All handlers read the bloc's current state through [ctx.getState] (a thunk)
/// so that, inside the async repository-watch closures, the *latest* state is
/// observed at each access rather than a value captured when the handler began.
class _CoreCrudDelegate {
  final _WeightBlocContext ctx;

  _CoreCrudDelegate(this.ctx);

  /// Subscribes to the repository watch stream and forwards emissions to
  /// [WeightLoaded], or to [WeightError] with the mapped
  /// [WeightRepositoryException].
  ///
  /// Re-subscriptions (e.g. after the app resumes from the background) keep the
  /// last-known entries visible while the new stream is established, so the UI
  /// never flashes an empty state and state consumers (like the CSV export)
  /// never observe a temporarily empty dataset. Only the very first load emits
  /// the [WeightLoading] skeleton.
  Future<void> onSubscribe(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    final currentEntries = ctx.entriesFromState(ctx.getState());

    if (currentEntries.isEmpty) {
      final state = ctx.getState();
      emit(
        WeightLoading(heightCm: state.heightCm, timePeriod: state.timePeriod),
      );
    }

    final Stream<List<WeightEntry>> watch;
    try {
      watch = ctx.repository.watchAllEntries();
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to start weight stream',
        fatal: false,
      );
      final errorType = e is WeightRepositoryException
          ? e.type
          : WeightErrorType.streamError;
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: errorType,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: currentEntries,
          filteredEntries: ctx.filterEntries(currentEntries, state.timePeriod),
        ),
      );
      return;
    }

    await emit.forEach<List<WeightEntry>>(
      watch,
      onData: (entries) {
        final state = ctx.getState();
        return WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        AppCrashReporter.recordError(
          error,
          stackTrace,
          reason:
              '[WeightBloc] Database stream emitted an infrastructure error',
          fatal: false,
        );
        final errorType = error is WeightRepositoryException
            ? error.type
            : WeightErrorType.streamError;
        final state = ctx.getState();
        final existingEntries = ctx.entriesFromState(state);
        return WeightError(
          errorType: errorType,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: existingEntries,
          filteredEntries: ctx.filterEntries(existingEntries, state.timePeriod),
        );
      },
    );
  }

  void onUpdateHeight(UpdateUserHeight event, Emitter<WeightState> emit) {
    final state = ctx.getState();
    final entries = ctx.entriesFromState(state);
    emit(
      WeightLoaded(
        heightCm: event.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: ctx.filterEntries(entries, state.timePeriod),
      ),
    );
  }

  /// Persists a new [WeightEntry] via the repository.
  ///
  /// Local-first: the entry is committed to the local repository before any
  /// platform interaction, and only then mirrored to the health platform as an
  /// unawaited, best-effort write when health sync is enabled (see
  /// [_WeightBlocContext.mirrorWrite]); mirror failures never fail the local
  /// add, and no platform call is made when sync is off.
  ///
  /// When the database holds no entries yet (e.g. the first onboarding
  /// measurement), a [WeightLoading] state is emitted so the UI never flashes
  /// the empty view while the write is in flight.
  Future<void> onAddWeight(AddWeight event, Emitter<WeightState> emit) async {
    final state = ctx.getState();
    final heightCm = state.heightCm;
    final entries = ctx.entriesFromState(state);

    // Emit loading state if this is the first entry (e.g., from onboarding
    // wizard). This prevents the TodayScreen from flashing the "empty" view
    // while the DB persists the initial measurement before the reactive stream
    // fires.
    if (entries.isEmpty) {
      emit(WeightLoading(heightCm: heightCm, timePeriod: state.timePeriod));
    }

    final entry = WeightEntry(
      weightKg: event.weightKg,
      dateTime: event.dateTime ?? DateTime.now(),
      note: event.note,
    );

    try {
      await ctx.repository.addEntry(entry);
      if (ctx.isHealthSyncEnabled) {
        unawaited(ctx.mirrorWrite(entry));
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to add entry',
        fatal: false,
      );
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: WeightErrorType.addEntryFailed,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Updates an existing [WeightEntry] in the repository.
  ///
  /// Local-first: the update is committed to the local repository before any
  /// platform interaction, and only then mirrored to the health platform as an
  /// unawaited, best-effort operation when health sync is enabled (see
  /// [_WeightBlocContext.mirrorUpdate]); mirror failures never fail the local
  /// update, and no platform call is made when sync is off.
  Future<void> onUpdateWeight(
    UpdateWeight event,
    Emitter<WeightState> emit,
  ) async {
    final state = ctx.getState();
    final heightCm = state.heightCm;
    final entries = ctx.entriesFromState(state);

    WeightEntry? oldEntry;
    for (final entry in entries) {
      if (entry.id == event.entry.id) {
        oldEntry = entry;
        break;
      }
    }

    try {
      await ctx.repository.addEntry(event.entry);
      if (ctx.isHealthSyncEnabled) {
        if (oldEntry != null) {
          unawaited(ctx.mirrorUpdate(oldEntry, event.entry));
        } else {
          unawaited(ctx.mirrorWrite(event.entry));
        }
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to update entry',
        fatal: false,
      );
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Deletes the entry with [DeleteWeight.id] via the repository and emits
  /// [WeightErrorType.deleteEntryFailed] on failure.
  ///
  /// Local-first: the local entry is removed first, and the deletion is then
  /// mirrored to the health platform as an unawaited, best-effort operation
  /// (see [_WeightBlocContext.mirrorDelete]) only when health sync is enabled
  /// and the target entry was found locally; mirror failures never fail the
  /// local delete.
  Future<void> onDeleteWeight(
    DeleteWeight event,
    Emitter<WeightState> emit,
  ) async {
    final entries = ctx.entriesFromState(ctx.getState());
    WeightEntry? target;
    for (final entry in entries) {
      if (entry.id == event.id) {
        target = entry;
        break;
      }
    }
    try {
      await ctx.repository.deleteEntry(event.id);
      if (ctx.isHealthSyncEnabled && target != null) {
        unawaited(ctx.mirrorDelete(target));
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to delete entry',
        fatal: false,
      );
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: WeightErrorType.deleteEntryFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  void onChangeChartFilter(ChangeChartFilter event, Emitter<WeightState> emit) {
    final state = ctx.getState();
    final entries = ctx.entriesFromState(state);

    emit(
      WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: event.period,
        entries: entries,
        filteredEntries: ctx.filterEntries(entries, event.period),
      ),
    );
  }

  Future<void> onRefreshWeightData(
    RefreshWeightData event,
    Emitter<WeightState> emit,
  ) async {
    try {
      final entries = await ctx.repository.getAllEntries();
      final state = ctx.getState();
      final heightCm = state.heightCm;
      final timePeriod = state.timePeriod;

      emit(
        WeightLoaded(
          heightCm: heightCm,
          timePeriod: timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, timePeriod),
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to refresh weight data',
        fatal: false,
      );
      final state = ctx.getState();
      final entries = ctx.entriesFromState(state);
      emit(
        WeightError(
          errorType: WeightErrorType.readFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        ),
      );
    } finally {
      final completer = event.completer;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> onClearAllWeightData(
    ClearAllWeightData event,
    Emitter<WeightState> emit,
  ) async {
    try {
      await ctx.repository.clearAllData();
      final state = ctx.getState();
      emit(
        WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: const [],
          filteredEntries: const [],
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to clear all data',
        fatal: false,
      );
      final state = ctx.getState();
      emit(
        WeightError(
          errorType: WeightErrorType.wipeFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: const [],
          filteredEntries: const [],
        ),
      );
    }
  }

  /// Bulk imports [ImportWeightEntries.entries] into the repository using the
  /// idempotent [WeightRepository.bulkImportEntries], then re-reads the full
  /// dataset and emits an updated [WeightLoaded] state.
  ///
  /// Deduplication is delegated entirely to
  /// [WeightRepository.bulkImportEntries] (±60 s / ±0.05 kg tolerance). The
  /// BLoC-level duplicate check is removed because it was less accurate and
  /// caused false skips on re-import.
  Future<void> onImportWeightEntries(
    ImportWeightEntries event,
    Emitter<WeightState> emit,
  ) async {
    try {
      final inserted = await ctx.repository.bulkImportEntries(event.entries);

      if (inserted > 0 && ctx.isHealthSyncEnabled) {
        unawaited(
          Future.forEach(event.entries, (entry) => ctx.mirrorWrite(entry)),
        );
      }

      final entries = await ctx.repository.getAllEntries();
      final state = ctx.getState();
      emit(
        WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: ctx.filterEntries(entries, state.timePeriod),
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to bulk import entries',
        fatal: false,
      );
      final state = ctx.getState();
      final currentEntries = ctx.entriesFromState(state);
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
