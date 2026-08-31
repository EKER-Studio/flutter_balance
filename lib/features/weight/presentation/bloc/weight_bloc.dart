import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/weight/domain/services/csv_weight_importer.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';

/// A BLoC managing weight entries and user height.
///
/// Subscribes to the reactive [WeightRepository.watchAllEntries] stream,
/// aggregates measurements per calendar day for chart display, and maps
/// repository failures to typed [WeightErrorType] states. Uses `HydratedBloc`
/// to persist [WeightState.heightCm] and the selected chart [TimePeriod]
/// across restarts.
///
/// ```dart
/// final bloc = WeightBloc(repository: repository)
///   ..add(const SubscribeToWeightChanges());
///
/// bloc.add(AddWeight(weightKg: 75.4, note: 'Morning'));
/// bloc.add(ChangeChartFilter(TimePeriod.month));
/// ```
@injectable
class WeightBloc extends HydratedBloc<WeightEvent, WeightState> {
  final WeightRepository repository;

  /// An optional settings BLoC used to gate health synchronization; when null,
  /// all health-sync behavior is dormant.
  final AppSettingsBloc? _settingsBloc;

  /// The backend used for every HealthKit / Health Connect interaction.
  final HealthService _healthService;

  late final HealthSyncCoordinator _healthSyncCoordinator;
  late final CsvWeightImporter _csvWeightImporter;

  List<WeightEntry>? _memoEntries;
  TimePeriod _memoPeriod = TimePeriod.week;
  List<WeightEntry> _memoResult = const [];

  WeightBloc({
    required this.repository,
    AppSettingsBloc? appSettingsBloc,
    HealthService? healthService,
    HealthSyncCoordinator? healthSyncCoordinator,
    CsvWeightImporter? csvWeightImporter,
  }) : _settingsBloc = appSettingsBloc,
       _healthService = healthService ?? NativeHealthService.instance,
       super(const WeightInitial()) {
    _healthSyncCoordinator =
        healthSyncCoordinator ??
        HealthSyncCoordinator(
          healthService: _healthService,
          repository: repository,
        );
    _csvWeightImporter =
        csvWeightImporter ?? CsvWeightImporter(repository: repository);

    on<SubscribeToWeightChanges>(
      _onSubscribeToWeightChanges,
      transformer: restartable(),
    );
    on<UpdateUserHeight>(_onUpdateUserHeight);
    on<AddWeight>(_onAddWeight, transformer: droppable());
    on<UpdateWeight>(_onUpdateWeight, transformer: droppable());
    on<DeleteWeight>(_onDeleteWeight, transformer: sequential());
    on<ChangeChartFilter>(_onChangeChartFilter, transformer: restartable());
    on<RefreshWeightData>(_onRefreshWeightData, transformer: droppable());
    on<ClearAllWeightData>(_onClearAllWeightData, transformer: droppable());
    on<ImportWeightEntries>(_onImportWeightEntries, transformer: droppable());
    on<SyncHealthEntries>(_onSyncHealthEntries, transformer: droppable());
    on<AnalyzeCsvFile>(_onAnalyzeCsvFile, transformer: droppable());
    on<ConfirmCsvImport>(_onConfirmCsvImport, transformer: droppable());
  }

  /// Whether health synchronization is currently enabled in app settings.
  bool get _isHealthSyncEnabled =>
      _settingsBloc?.state.isHealthSyncEnabled ?? false;

  /// Extracts the persisted entries from any [WeightState], falling back to
  /// an empty list for [WeightInitial] and [WeightLoading].
  static List<WeightEntry> _entriesFromState(WeightState state) =>
      state.entries;

  /// Filters [entries] by [period] and aggregates them per calendar day.
  ///
  /// Uses a memoized result keyed on the entry content so identical stream
  /// emissions skip the filter and aggregation work entirely.
  List<WeightEntry> _filterEntries(
    List<WeightEntry> entries,
    TimePeriod period,
  ) {
    if (period == _memoPeriod && _sameEntries(entries, _memoEntries)) {
      return _memoResult;
    }
    final filtered = switch (period) {
      TimePeriod.all => entries,
      TimePeriod.week || TimePeriod.month || TimePeriod.year =>
        entries
            .where(
              (e) => e.dateTime.isAfter(
                DateTime.now().subtract(period.lookbackDuration),
              ),
            )
            .toList(),
    };
    final result = _aggregateByDay(filtered);
    _memoEntries = entries;
    _memoPeriod = period;
    _memoResult = result;
    return result;
  }

  /// Compares two entry lists by content key without relying on identity.
  ///
  /// Reactive streams always allocate new list and entry instances, so
  /// `identical`/`listEquals` can never detect an unchanged dataset. Each
  /// element's stable key (id + dateTime + weightKg) is compared in a single
  /// allocation-free pass, which is far cheaper than re-running the filter and
  /// day aggregation on every stream emission.
  static bool _sameEntries(List<WeightEntry> entries, List<WeightEntry>? memo) {
    if (identical(entries, memo)) return true;
    if (memo == null || entries.length != memo.length) return false;
    for (var i = 0; i < entries.length; i++) {
      final current = entries[i];
      final cached = memo[i];
      if (current.id != cached.id ||
          current.dateTime != cached.dateTime ||
          current.weightKg != cached.weightKg) {
        return false;
      }
    }
    return true;
  }

  /// Aggregates [entries] so that multiple measurements on the same calendar
  /// day are collapsed into a single averaged data point.
  ///
  /// The merged entry carries the mean [WeightEntry.weightKg] for that day,
  /// with [WeightEntry.dateTime] set to noon (12:00) of the day to keep the
  /// X-axis positions stable across re-renders.
  List<WeightEntry> _aggregateByDay(List<WeightEntry> entries) {
    final Map<DateTime, List<WeightEntry>> grouped = {};
    for (final e in entries) {
      final dayKey = DateTime(
        e.dateTime.year,
        e.dateTime.month,
        e.dateTime.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((dayKey) {
      // The key is taken from grouped.keys, so the lookup always succeeds.
      final dayEntries = grouped[dayKey]!;
      final avgWeight =
          dayEntries.map((e) => e.weightKg).reduce((a, b) => a + b) /
          dayEntries.length;

      final noonDate = DateTime(dayKey.year, dayKey.month, dayKey.day, 12);
      return WeightEntry(
        id: dayEntries.first.id,
        weightKg: (avgWeight * 100).round() / 100,
        dateTime: noonDate,
      );
    }).toList();
  }

  /// Subscribes to the repository watch stream and forwards emissions to
  /// [WeightLoaded], or to [WeightError] with the mapped [WeightRepositoryException].
  ///
  /// Re-subscriptions (e.g. after the app resumes from the background) keep
  /// the last-known entries visible while the new stream is established, so
  /// the UI never flashes an empty state and state consumers (like the CSV
  /// export) never observe a temporarily empty dataset. Only the very first
  /// load emits the [WeightLoading] skeleton.
  Future<void> _onSubscribeToWeightChanges(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    final currentEntries = _entriesFromState(state);

    if (currentEntries.isEmpty) {
      // Emit loading state while establishing the new subscription.
      emit(
        WeightLoading(heightCm: state.heightCm, timePeriod: state.timePeriod),
      );
    }

    final Stream<List<WeightEntry>> watch;
    try {
      watch = repository.watchAllEntries();
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
      emit(
        WeightError(
          errorType: errorType,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: currentEntries,
          filteredEntries: _filterEntries(currentEntries, state.timePeriod),
        ),
      );
      return;
    }

    await emit.forEach<List<WeightEntry>>(
      watch,
      onData: (entries) => WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: _filterEntries(entries, state.timePeriod),
      ),
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
        final existingEntries = _entriesFromState(state);
        return WeightError(
          errorType: errorType,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: existingEntries,
          filteredEntries: _filterEntries(existingEntries, state.timePeriod),
        );
      },
    );
  }

  void _onUpdateUserHeight(UpdateUserHeight event, Emitter<WeightState> emit) {
    final entries = _entriesFromState(state);
    emit(
      WeightLoaded(
        heightCm: event.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: _filterEntries(entries, state.timePeriod),
      ),
    );
  }

  /// Persists a new [WeightEntry] via the repository, validating that the
  /// user's height is set first (emits [WeightErrorType.heightNotSet] otherwise).
  ///
  /// Local-first: the entry is committed to the local repository before any
  /// platform interaction, and only then mirrored to the health platform as
  /// an unawaited, best-effort write when health sync is enabled (see
  /// [_mirrorWriteToHealth]); mirror failures never fail the local add, and
  /// no platform call is made when sync is off.
  ///
  /// When the database holds no entries yet (e.g. the first onboarding
  /// measurement), a [WeightLoading] state is emitted so the UI never flashes
  /// the empty view while the write is in flight.
  Future<void> _onAddWeight(AddWeight event, Emitter<WeightState> emit) async {
    final heightCm = state.heightCm;
    final entries = _entriesFromState(state);

    if (heightCm == null || heightCm <= 0) {
      emit(
        WeightError(
          errorType: WeightErrorType.heightNotSet,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
      return;
    }

    // Emit loading state if this is the first entry (e.g., from onboarding wizard).
    // This prevents the TodayScreen from flashing the "empty" view while the DB
    // persists the initial measurement before the reactive stream fires.
    if (entries.isEmpty) {
      emit(WeightLoading(heightCm: heightCm, timePeriod: state.timePeriod));
    }

    final entry = WeightEntry(
      weightKg: event.weightKg,
      dateTime: event.dateTime ?? DateTime.now(),
      note: event.note,
    );

    try {
      await repository.addEntry(entry);
      if (_isHealthSyncEnabled) {
        unawaited(_mirrorWriteToHealth(entry));
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to add entry',
        fatal: false,
      );
      emit(
        WeightError(
          errorType: WeightErrorType.addEntryFailed,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Updates an existing [WeightEntry] in the repository.
  ///
  /// Local-first: the update is committed to the local repository before any
  /// platform interaction, and only then mirrored to the health platform as
  /// an unawaited, best-effort operation when health sync is enabled (see
  /// [_mirrorUpdateToHealth]); mirror failures never fail the local update, and
  /// no platform call is made when sync is off.
  Future<void> _onUpdateWeight(
    UpdateWeight event,
    Emitter<WeightState> emit,
  ) async {
    final heightCm = state.heightCm;
    final entries = _entriesFromState(state);

    if (heightCm == null || heightCm <= 0) {
      emit(
        WeightError(
          errorType: WeightErrorType.heightNotSet,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
      return;
    }

    WeightEntry? oldEntry;
    for (final entry in entries) {
      if (entry.id == event.entry.id) {
        oldEntry = entry;
        break;
      }
    }

    try {
      await repository.addEntry(event.entry);
      if (_isHealthSyncEnabled) {
        if (oldEntry != null) {
          unawaited(_mirrorUpdateToHealth(oldEntry, event.entry));
        } else {
          unawaited(_mirrorWriteToHealth(event.entry));
        }
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to update entry',
        fatal: false,
      );
      emit(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Deletes the entry with [DeleteWeight.id] via the repository and emits
  /// [WeightErrorType.deleteEntryFailed] on failure.
  ///
  /// Local-first: the local entry is removed first, and the deletion is then
  /// mirrored to the health platform as an unawaited, best-effort operation
  /// (see [_mirrorDeleteToHealth]) only when health sync is enabled and the
  /// target entry was found locally; mirror failures never fail the local
  /// delete.
  Future<void> _onDeleteWeight(
    DeleteWeight event,
    Emitter<WeightState> emit,
  ) async {
    final entries = _entriesFromState(state);
    WeightEntry? target;
    for (final entry in entries) {
      if (entry.id == event.id) {
        target = entry;
        break;
      }
    }
    try {
      await repository.deleteEntry(event.id);
      if (_isHealthSyncEnabled && target != null) {
        unawaited(_mirrorDeleteToHealth(target));
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to delete entry',
        fatal: false,
      );
      emit(
        WeightError(
          errorType: WeightErrorType.deleteEntryFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Mirrors a locally persisted [entry] to the health platform on a
  /// best-effort basis; failures are logged and reported to Crashlytics but never propagated.
  Future<void> _mirrorWriteToHealth(WeightEntry entry) async {
    if (!_isHealthSyncEnabled) return;
    await _healthSyncCoordinator.mirrorWrite(entry);
  }

  /// Mirrors a local deletion of [entry] to the health platform on a
  /// best-effort basis; failures are logged and reported to Crashlytics but never propagated.
  Future<void> _mirrorDeleteToHealth(WeightEntry entry) async {
    if (!_isHealthSyncEnabled) return;
    await _healthSyncCoordinator.mirrorDelete(entry.weightKg, entry.dateTime);
  }

  /// Mirrors an updated [newEntry] to the health platform by removing the
  /// outdated record [oldEntry] (if weight or timestamp changed) and inserting
  /// the new measurement. If only the note changed, skips the health platform
  /// call since health services do not store weight notes.
  Future<void> _mirrorUpdateToHealth(
    WeightEntry oldEntry,
    WeightEntry newEntry,
  ) async {
    if (!_isHealthSyncEnabled) return;
    final isWeightChanged = oldEntry.weightKg != newEntry.weightKg;
    final isTimeChanged = oldEntry.dateTime != newEntry.dateTime;

    if (isWeightChanged || isTimeChanged) {
      await _healthSyncCoordinator.mirrorDelete(
        oldEntry.weightKg,
        oldEntry.dateTime,
      );
      await _healthSyncCoordinator.mirrorWrite(newEntry);
    }
  }

  /// Pulls weight history from the health platform and merges records that do
  /// not already exist locally, emitting a refreshed [WeightLoaded] state.
  Future<void> _onSyncHealthEntries(
    SyncHealthEntries event,
    Emitter<WeightState> emit,
  ) async {
    if (!_isHealthSyncEnabled || _settingsBloc == null) return;
    AppAnalytics.logHealthSyncStarted();
    final result = await _healthSyncCoordinator.sync(
      startDate: event.startDate,
      lastSyncTime: _settingsBloc.state.lastHealthSyncTimestamp,
    );
    if (result != null) {
      _settingsBloc.add(UpdateLastHealthSyncTimestamp(result.syncTimestamp));
    }
  }

  void _onChangeChartFilter(
    ChangeChartFilter event,
    Emitter<WeightState> emit,
  ) {
    final entries = _entriesFromState(state);

    emit(
      WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: event.period,
        entries: entries,
        filteredEntries: _filterEntries(entries, event.period),
      ),
    );
  }

  /// Re-reads all entries from the repository and emits a fresh [WeightLoaded]
  /// state, emitting [WeightErrorType.readFailed] on failure.
  Future<void> _onRefreshWeightData(
    RefreshWeightData event,
    Emitter<WeightState> emit,
  ) async {
    try {
      final entries = await repository.getAllEntries();
      final heightCm = state.heightCm;
      final timePeriod = state.timePeriod;

      emit(
        WeightLoaded(
          heightCm: heightCm,
          timePeriod: timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, timePeriod),
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to refresh weight data',
        fatal: false,
      );
      final entries = _entriesFromState(state);
      emit(
        WeightError(
          errorType: WeightErrorType.readFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  /// Wipes all stored weight data and emits an empty [WeightLoaded] state,
  /// emitting [WeightErrorType.wipeFailed] on failure.
  Future<void> _onClearAllWeightData(
    ClearAllWeightData event,
    Emitter<WeightState> emit,
  ) async {
    try {
      await repository.clearAllData();
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
  /// Deduplication is delegated entirely to [WeightRepository.bulkImportEntries]
  /// (±60 s / ±0.05 kg tolerance). The BLoC-level duplicate check is removed
  /// because it was less accurate and caused false skips on re-import.
  Future<void> _onImportWeightEntries(
    ImportWeightEntries event,
    Emitter<WeightState> emit,
  ) async {
    try {
      final inserted = await repository.bulkImportEntries(event.entries);

      if (inserted > 0 && _isHealthSyncEnabled) {
        unawaited(
          Future.forEach(event.entries, (entry) => _mirrorWriteToHealth(entry)),
        );
      }

      final entries = await repository.getAllEntries();
      emit(
        WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to bulk import entries',
        fatal: false,
      );
      final currentEntries = _entriesFromState(state);
      emit(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: currentEntries,
          filteredEntries: _filterEntries(currentEntries, state.timePeriod),
        ),
      );
    }
  }

  /// Reads and parses a CSV file on a background isolate without writing to the
  /// database (dry-run analysis).
  Future<void> _onAnalyzeCsvFile(
    AnalyzeCsvFile event,
    Emitter<WeightState> emit,
  ) async {
    final currentEntries = _entriesFromState(state);
    emit(
      CsvAnalysisInProgress(
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: currentEntries,
        filteredEntries: _filterEntries(currentEntries, state.timePeriod),
      ),
    );

    final outcome = await _csvWeightImporter.analyzeFile(event.filePath);
    switch (outcome) {
      case CsvAnalysisSuccess(:final analysis):
        emit(
          CsvAnalysisReady(
            heightCm: state.heightCm,
            timePeriod: state.timePeriod,
            entries: currentEntries,
            filteredEntries: _filterEntries(currentEntries, state.timePeriod),
            analysis: analysis,
          ),
        );
      case CsvAnalysisFailure(:final errorType):
        emit(
          CsvAnalysisError(
            errorType: errorType,
            heightCm: state.heightCm,
            timePeriod: state.timePeriod,
            entries: currentEntries,
            filteredEntries: _filterEntries(currentEntries, state.timePeriod),
          ),
        );
    }
  }

  /// Persists the [ConfirmCsvImport.validEntries] via the idempotent repository
  /// bulk import and emits [WeightImportSuccess] with the inserted-entry count.
  Future<void> _onConfirmCsvImport(
    ConfirmCsvImport event,
    Emitter<WeightState> emit,
  ) async {
    final currentEntries = _entriesFromState(state);
    try {
      final count = await _csvWeightImporter.confirmImport(event.validEntries);

      if (_isHealthSyncEnabled && event.validEntries.isNotEmpty) {
        unawaited(
          Future.forEach(
            event.validEntries,
            (entry) => _mirrorWriteToHealth(entry),
          ),
        );
      }

      final updatedEntries = await repository.getAllEntries();
      final filtered = _filterEntries(updatedEntries, state.timePeriod);
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
      emit(
        WeightError(
          errorType: WeightErrorType.writeFailed,
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: currentEntries,
          filteredEntries: _filterEntries(currentEntries, state.timePeriod),
        ),
      );
    }
  }

  /// Restores the persisted [WeightState.heightCm] and chart [TimePeriod]
  /// from the hydrated JSON map, defaulting to [TimePeriod.week].
  @override
  WeightState? fromJson(Map<String, dynamic> json) {
    final periodString = json['timePeriod'] as String?;
    final period = periodString != null
        ? TimePeriod.values.firstWhere(
            (e) => e.name == periodString,
            orElse: () => TimePeriod.week,
          )
        : TimePeriod.week;

    return WeightInitial(
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      timePeriod: period,
    );
  }

  /// Serializes only the lightweight user preferences ([WeightState.heightCm]
  /// and the [WeightState.timePeriod] name) for hydration, omitting the
  /// dynamic entry lists to avoid redundant disk I/O.
  @override
  Map<String, dynamic>? toJson(WeightState state) {
    return {'heightCm': state.heightCm, 'timePeriod': state.timePeriod.name};
  }
}
