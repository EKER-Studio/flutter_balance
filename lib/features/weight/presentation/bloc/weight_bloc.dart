import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/domain/repositories/health_sync_settings.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/features/weight/domain/services/csv_weight_importer.dart';
import 'package:balance/features/weight/domain/services/health_sync_coordinator.dart';
import 'package:balance/features/weight/domain/services/weight_chart_calculator.dart';

part 'weight_bloc_core_delegate.dart';
part 'weight_bloc_health_sync_delegate.dart';
part 'weight_bloc_csv_import_delegate.dart';

/// A BLoC managing weight entries and user height.
///
/// Subscribes to the reactive [WeightRepository.watchAllEntries] stream,
/// aggregates measurements per calendar day for chart display, and maps
/// repository failures to typed [WeightErrorType] states. Uses `HydratedBloc`
/// to persist [WeightState.heightCm] and the selected chart [TimePeriod]
/// across restarts.
///
/// The event handlers are split across three private per-domain delegates
/// ([_CoreCrudDelegate], [_HealthSyncDelegate], [_CsvImportDelegate]) that
/// share a single [_WeightBlocContext]. The public API (events, states,
/// constructor, DI registration, [close], [fromJson]/[toJson]) is unchanged;
/// this class is now a thin dispatcher that routes each event to its delegate.
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
  final HealthSyncSettings? _healthSyncSettings;

  /// The backend used for every HealthKit / Health Connect interaction.
  final HealthService _healthService;

  /// Shared mutable state and cross-domain helpers used by every delegate.
  late final _WeightBlocContext _ctx;

  late final _CoreCrudDelegate _core;
  late final _HealthSyncDelegate _healthSync;
  late final _CsvImportDelegate _csvImport;

  WeightBloc({
    required this.repository,
    HealthSyncSettings? appSettingsBloc,
    HealthService? healthService,
    HealthSyncCoordinator? healthSyncCoordinator,
    CsvWeightImporter? csvWeightImporter,
  }) : _healthSyncSettings = appSettingsBloc,
       _healthService = healthService ?? NativeHealthService.instance,
       super(WeightInitial()) {
    _ctx = _WeightBlocContext(
      repository: repository,
      healthSyncSettings: _healthSyncSettings,
      healthService: _healthService,
    );
    _ctx.healthSyncCoordinator =
        healthSyncCoordinator ??
        HealthSyncCoordinator(
          healthService: _healthService,
          repository: repository,
        );
    _ctx.csvWeightImporter =
        csvWeightImporter ?? const _UnavailableCsvWeightImporter();
    _ctx.getState = () => state;

    _core = _CoreCrudDelegate(_ctx);
    _healthSync = _HealthSyncDelegate(_ctx);
    _csvImport = _CsvImportDelegate(_ctx);

    on<SubscribeToWeightChanges>(_onSubscribe, transformer: restartable());
    on<UpdateUserHeight>(_onUpdateHeight);
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

  /// Releases the in-memory memo cache held by [_filterEntries] and then
  /// closes the bloc.
  ///
  /// The bloc itself owns no external resources: the repository watch stream
  /// is managed by the `restartable()` transformer (cancelled automatically
  /// when the bloc is closed), and the health-sync coordinator / importer only
  /// reference dependencies that live in the DI container. The one piece of
  /// state worth clearing explicitly is the memo cache, which can hold a copy
  /// of the full entry list between recomputations; dropping those references
  /// on close lets the garbage collector reclaim them promptly instead of
  /// keeping the last chart's data alive for the bloc's lifetime.
  @override
  Future<void> close() async {
    _ctx.clearMemoCache();
    await super.close();
  }

  // ---------------------------------------------------------------------------
  // Thin dispatcher: each handler forwards to its per-domain delegate. The
  // transformers (restartable / droppable / sequential) are registered here so
  // the concurrency semantics are identical to the original single-class design.
  // ---------------------------------------------------------------------------

  Future<void> _onSubscribe(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) => _core.onSubscribe(event, emit);

  void _onUpdateHeight(UpdateUserHeight event, Emitter<WeightState> emit) =>
      _core.onUpdateHeight(event, emit);

  Future<void> _onAddWeight(AddWeight event, Emitter<WeightState> emit) =>
      _core.onAddWeight(event, emit);

  Future<void> _onUpdateWeight(UpdateWeight event, Emitter<WeightState> emit) =>
      _core.onUpdateWeight(event, emit);

  Future<void> _onDeleteWeight(DeleteWeight event, Emitter<WeightState> emit) =>
      _core.onDeleteWeight(event, emit);

  void _onChangeChartFilter(
    ChangeChartFilter event,
    Emitter<WeightState> emit,
  ) => _core.onChangeChartFilter(event, emit);

  Future<void> _onRefreshWeightData(
    RefreshWeightData event,
    Emitter<WeightState> emit,
  ) => _core.onRefreshWeightData(event, emit);

  Future<void> _onClearAllWeightData(
    ClearAllWeightData event,
    Emitter<WeightState> emit,
  ) => _core.onClearAllWeightData(event, emit);

  Future<void> _onImportWeightEntries(
    ImportWeightEntries event,
    Emitter<WeightState> emit,
  ) => _core.onImportWeightEntries(event, emit);

  Future<void> _onSyncHealthEntries(
    SyncHealthEntries event,
    Emitter<WeightState> emit,
  ) => _healthSync.onSync(event, emit);

  Future<void> _onAnalyzeCsvFile(
    AnalyzeCsvFile event,
    Emitter<WeightState> emit,
  ) => _csvImport.onAnalyze(event, emit);

  Future<void> _onConfirmCsvImport(
    ConfirmCsvImport event,
    Emitter<WeightState> emit,
  ) => _csvImport.onConfirm(event, emit);

  /// Restores the persisted [WeightState.heightCm] and chart [TimePeriod]
  /// from the hydrated JSON map, defaulting to [TimePeriod.week].
  @override
  WeightState? fromJson(Map<String, dynamic> json) {
    final periodValue = json['timePeriod'];
    final periodString = periodValue is String ? periodValue : null;
    final period = periodString != null
        ? TimePeriod.values.firstWhere(
            (e) => e.name == periodString,
            orElse: () => TimePeriod.week,
          )
        : TimePeriod.week;

    return WeightInitial(
      heightCm: json['heightCm'] is num
          ? (json['heightCm'] as num).toDouble()
          : null,
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

/// Shared, mutable state and cross-domain helpers for the [WeightBloc]
/// delegates.
///
/// The three per-domain delegates ([_CoreCrudDelegate], [_HealthSyncDelegate],
/// [_CsvImportDelegate]) all operate on the same reactive repository stream and
/// the same hydrated [WeightState] (height + time period), so they cannot be
/// split into independent BLoCs. Instead they share this context, which holds
/// the dependencies, the memo cache, and the health-mirror helpers used by both
/// the core CRUD and CSV-import paths.
///
/// `getState` is a thunk (not a captured value) so that handlers read the
/// bloc's *current* state at each access point — critical inside the async
/// `onData`/`onError` closures of the repository watch, where the state may
/// have changed between emissions.
class _WeightBlocContext {
  final WeightRepository repository;
  final HealthSyncSettings? healthSyncSettings;
  final HealthService healthService;

  late final HealthSyncCoordinator healthSyncCoordinator;
  late final CsvWeightImporter csvWeightImporter;

  /// Thunk that returns the bloc's current [WeightState]. Set by the bloc after
  /// construction so handlers always observe fresh state.
  late final WeightState Function() getState;

  List<WeightEntry>? memoEntries;
  TimePeriod memoPeriod = TimePeriod.week;
  List<WeightEntry> memoResult = const [];

  _WeightBlocContext({
    required this.repository,
    required this.healthSyncSettings,
    required this.healthService,
  });

  /// Whether health synchronization is currently enabled in app settings.
  bool get isHealthSyncEnabled =>
      healthSyncSettings?.isHealthSyncEnabled ?? false;

  List<WeightEntry> entriesFromState(WeightState state) => state.entries;

  /// Filters [entries] by [period] and aggregates them per calendar day.
  ///
  /// Delegates pure calculations to [WeightChartCalculator] while keeping a
  /// memo cache here so identical stream emissions skip recomputation.
  List<WeightEntry> filterEntries(
    List<WeightEntry> entries,
    TimePeriod period,
  ) {
    if (period == memoPeriod &&
        WeightChartCalculator.sameEntries(entries, memoEntries)) {
      return memoResult;
    }
    final result = WeightChartCalculator.filterAndAggregate(entries, period);
    memoEntries = entries;
    memoPeriod = period;
    memoResult = result;
    return result;
  }

  /// Drops the memo cache so the next [filterEntries] call recomputes. Called
  /// from [WeightBloc.close].
  void clearMemoCache() {
    memoEntries = null;
    memoResult = const [];
  }

  /// Mirrors a locally persisted [entry] to the health platform on a
  /// best-effort basis; failures are logged and reported to Crashlytics but
  /// never propagated.
  Future<void> mirrorWrite(WeightEntry entry) async {
    if (!isHealthSyncEnabled) return;
    try {
      await healthSyncCoordinator.mirrorWrite(entry);
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to mirror weight to health service',
        fatal: false,
      );
    }
  }

  /// Mirrors a local deletion of [entry] to the health platform on a
  /// best-effort basis; failures are logged and reported to Crashlytics but
  /// never propagated.
  Future<void> mirrorDelete(WeightEntry entry) async {
    if (!isHealthSyncEnabled) return;
    try {
      await healthSyncCoordinator.mirrorDelete(entry.weightKg, entry.dateTime);
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: '[WeightBloc] Failed to delete weight from health service',
        fatal: false,
      );
    }
  }

  /// Mirrors an updated [newEntry] to the health platform by removing the
  /// outdated record [oldEntry] (if weight or timestamp changed) and inserting
  /// the new measurement. If only the note changed, skips the health platform
  /// call since health services do not store weight notes.
  Future<void> mirrorUpdate(WeightEntry oldEntry, WeightEntry newEntry) async {
    if (!isHealthSyncEnabled) return;
    final isWeightChanged = oldEntry.weightKg != newEntry.weightKg;
    final isTimeChanged = oldEntry.dateTime != newEntry.dateTime;

    try {
      if (isWeightChanged || isTimeChanged) {
        await healthSyncCoordinator.mirrorDelete(
          oldEntry.weightKg,
          oldEntry.dateTime,
        );
        await healthSyncCoordinator.mirrorWrite(newEntry);
      }
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason:
            '[WeightBloc] Failed to mirror updated weight to health service',
        fatal: false,
      );
    }
  }
}

final class _UnavailableCsvWeightImporter implements CsvWeightImporter {
  const _UnavailableCsvWeightImporter();

  @override
  Future<CsvAnalysisOutcome> analyzeFile(String filePath) async =>
      const CsvAnalysisFailure(CsvErrorType.invalidFormat);

  @override
  Future<int> confirmImport(List<WeightEntry> entries) async {
    throw StateError('CsvWeightImporter was not provided.');
  }
}
