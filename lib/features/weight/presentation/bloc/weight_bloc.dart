
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';

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
///// ```
class WeightBloc extends HydratedBloc<WeightEvent, WeightState> {
  /// The [WeightRepository] backing data operations.
  final WeightRepository repository;

  /// An optional settings BLoC used to gate health synchronization; when null,
  /// all health-sync behavior is dormant.
  final AppSettingsBloc? _settingsBloc;

  /// The backend used for every HealthKit / Health Connect interaction.
  final HealthService _healthService;

  List<WeightEntry>? _memoEntries;
  TimePeriod _memoPeriod = TimePeriod.week;
  List<WeightEntry> _memoResult = const [];

  /// Creates a [WeightBloc] backed by the given [repository].
  ///
  /// @param repository Source of weight data.
  /// @param appSettingsBloc Optional settings BLoC consulted for the health
  /// sync toggle; health-sync behavior stays dormant when omitted.
  /// @param healthService Optional health backend; defaults to
  /// [NativeHealthService.instance].
  WeightBloc({
    required this.repository,
    AppSettingsBloc? appSettingsBloc,
    HealthService? healthService,
  }) : _settingsBloc = appSettingsBloc,
       _healthService = healthService ?? NativeHealthService.instance,
       super(const WeightInitial()) {
    on<SubscribeToWeightChanges>(_onSubscribeToWeightChanges);
    on<UpdateUserHeight>(_onUpdateUserHeight);
    on<AddWeight>(_onAddWeight);
    on<DeleteWeight>(_onDeleteWeight);
    on<ChangeChartFilter>(_onChangeChartFilter);
    on<RefreshWeightData>(_onRefreshWeightData);
    on<ClearAllWeightData>(_onClearAllWeightData);
    on<ImportWeightEntries>(_onImportWeightEntries);
    on<SyncHealthEntries>(_onSyncHealthEntries);
  }

  /// Whether health synchronization is currently enabled in app settings.
  bool get _isHealthSyncEnabled =>
      _settingsBloc?.state.isHealthSyncEnabled ?? false;

  /// Extracts the persisted entries from any [WeightState], falling back to
  /// an empty list for [WeightInitial] and [WeightLoading].
  static List<WeightEntry> _entriesFromState(WeightState state) {
    return switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
  }

  /// Filters [entries] by [period] and aggregates them per calendar day.
  ///
  /// Uses a memoized result keyed on the entry content so identical stream
  ///// emissions skip the filter and aggregation work entirely.
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
  ///// X-axis positions stable across re-renders.
  List<WeightEntry> _aggregateByDay(List<WeightEntry> entries) {
    if (entries.length <= 1) return entries;

    // Group by date (year-month-day)
    final Map<String, List<WeightEntry>> grouped = {};
    for (final e in entries) {
      final key = '${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((key) {
      // The key is taken from grouped.keys, so the lookup always succeeds.
      final dayEntries = grouped[key]!;
      final avgWeight =
          dayEntries.map((e) => e.weightKg).reduce((a, b) => a + b) /
          dayEntries.length;

      final representative = dayEntries.first.dateTime;
      final noonDate = DateTime(
        representative.year,
        representative.month,
        representative.day,
        12,
      );
      return WeightEntry(
        id: dayEntries.first.id,
        weightKg: (avgWeight * 100).round() / 100,
        dateTime: noonDate,
      );
    }).toList();
  }

  /// Subscribes to the repository watch stream and forwards emissions to
  ///// [WeightLoaded], or to [WeightError] with the mapped [WeightRepositoryException].
  Future<void> _onSubscribeToWeightChanges(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    // Emit loading state while establishing the new subscription.
    emit(WeightLoading(heightCm: state.heightCm, timePeriod: state.timePeriod));

    await emit.forEach<List<WeightEntry>>(
      repository.watchAllEntries(),
      onData: (entries) => WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: _filterEntries(entries, state.timePeriod),
      ),
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[WeightBloc] Database stream emitted an infrastructure error: '
            '$error\n$stackTrace',
          );
        }
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

  /// Persists the new [UpdateUserHeight.heightCm] and re-emits the current
  /// entries with an updated [WeightLoaded] state.
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
  ///// the empty view while the write is in flight.
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Failed to add entry: $e\n$stack');
      }
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

  /// Deletes the entry with [DeleteWeight.id] via the repository and emits
  /// [WeightErrorType.deleteEntryFailed] on failure.
  ///
  /// Local-first: the local entry is removed first, and the deletion is then
  /// mirrored to the health platform as an unawaited, best-effort operation
  /// (see [_mirrorDeleteToHealth]) only when health sync is enabled and the
  /// target entry was found locally; mirror failures never fail the local
  ///// delete.
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Failed to delete entry: $e\n$stack');
      }
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
  ///// best-effort basis; failures are logged but never propagated.
  Future<void> _mirrorWriteToHealth(WeightEntry entry) async {
    try {
      await _healthService.writeWeight(
        weightKg: entry.weightKg,
        timestamp: entry.dateTime,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WeightBloc] Health mirror write failed: $e\n$stack');
      }
    }
  }

  /// Mirrors a local deletion of [entry] to the health platform on a
  ///// best-effort basis; failures are logged but never propagated.
  Future<void> _mirrorDeleteToHealth(WeightEntry entry) async {
    try {
      await _healthService.deleteWeight(
        weightKg: entry.weightKg,
        timestamp: entry.dateTime,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WeightBloc] Health mirror delete failed: $e\n$stack');
      }
    }
  }

  /// Pulls weight history from the health platform and merges records that do
  /// not already exist locally, emitting a refreshed [WeightLoaded] state.
  ///
  /// The sync window spans [SyncHealthEntries.startDate] (defaulting to the
  /// deep past so historical records are never missed) through the current
  /// instant. Each remote record is
  /// deduplicated against the local database: it is imported only when no
  /// local entry matches its weight and its timestamp truncated to seconds in
  /// UTC (see [_isLocalDuplicate]). This also filters out entries that were
  /// previously mirrored to the health platform via [_mirrorWriteToHealth],
  /// which breaks the write -> sync -> write ping-pong loop.
  ///
  /// Local-first: the database is the single source of truth. Remote records
  /// are merged in but never overwrite or delete local data, and the import
  /// itself never triggers mirror writes, so a sync pass cannot re-enter
  /// itself. The pull aborts silently (no state change) when health sync is
  ///// disabled, the platform errors out, or there are no new records.
  Future<void> _onSyncHealthEntries(
    SyncHealthEntries event,
    Emitter<WeightState> emit,
  ) async {
    if (!_isHealthSyncEnabled) return;
    try {
      final end = DateTime.now();
      final start = event.startDate ?? DateTime(2000);
      final remoteEntries = await _healthService.fetchWeightHistory(
        start: start,
        end: end,
      );

      final localEntries = await repository.getAllEntries();

      // 1. Pull remote records missing from local database
      if (remoteEntries.isNotEmpty) {
        final newLocalEntries = remoteEntries
            .where((remote) => !_isDuplicate(remote, localEntries))
            .toList();
        if (newLocalEntries.isNotEmpty) {
          await repository.bulkImportEntries(newLocalEntries);
        }
      }

      // 2. Push local records missing from remote health platform
      final missingRemoteEntries = localEntries
          .where((local) => !_isDuplicate(local, remoteEntries))
          .toList();

      if (missingRemoteEntries.isNotEmpty) {
        // Run in background to avoid blocking the bloc if there are many entries
        unawaited(
          Future.forEach(
            missingRemoteEntries,
            (entry) => _mirrorWriteToHealth(entry),
          ),
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Health sync failed: $e\n$stack');
      }
    }
  }

  /// Returns true if [target] already exists in [entries]: an entry
  /// with the same timestamp truncated to the minute (UTC-normalized) and a
  /// weight value within 0.01kg tolerance.
  static bool _isDuplicate(WeightEntry target, List<WeightEntry> entries) {
    final targetInstant = _truncateToMinuteUtc(target.dateTime);
    for (final e in entries) {
      if ((e.weightKg - target.weightKg).abs() < 0.01 &&
          _truncateToMinuteUtc(e.dateTime) == targetInstant) {
        return true;
      }
    }
    return false;
  }

  /// Truncates [dateTime] to minute precision in UTC so measurements recorded
  /// seconds apart — possibly in different timezone representations — are
  /// still treated as the same measurement.
  static DateTime _truncateToMinuteUtc(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute);
  }

  /// Re-emits the current entries filtered by the newly selected chart
  /// [ChangeChartFilter.period].
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
  ///// state, emitting [WeightErrorType.readFailed] on failure.
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Failed to refresh weight data: $e\n$stack');
      }
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
  ///// emitting [WeightErrorType.wipeFailed] on failure.
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Failed to clear data: $e\n$stack');
      }
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

  /// Bulk imports [ImportWeightEntries.entries] into the repository, then
  ///// re-reads the full dataset and emits an updated [WeightLoaded] state.
  Future<void> _onImportWeightEntries(
    ImportWeightEntries event,
    Emitter<WeightState> emit,
  ) async {
    try {
      final localEntries = await repository.getAllEntries();
      final newEntries = <WeightEntry>[];

      for (final entry in event.entries) {
        if (!_isDuplicate(entry, localEntries) &&
            !_isDuplicate(entry, newEntries)) {
          newEntries.add(entry);
        }
      }

      if (newEntries.isNotEmpty) {
        await repository.bulkImportEntries(newEntries);

        if (_isHealthSyncEnabled) {
          unawaited(
            Future.forEach(newEntries, (entry) => _mirrorWriteToHealth(entry)),
          );
        }
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
      if (kDebugMode) {
        debugPrint('[WeightBloc] Failed to import entries: $e\n$stack');
      }
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
    // Omit dynamic data collections (entries & filteredEntries) from JSON persistence
    // to prevent redundant disk I/O. Only lightweight user preferences are serialized.
    return {'heightCm': state.heightCm, 'timePeriod': state.timePeriod.name};
  }
}
