import 'dart:async';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';

/// BLoC managing weight entries and user height.
///
/// Uses [HydratedBloc] to persist [WeightState.heightCm] across restarts.
class WeightBloc extends HydratedBloc<WeightEvent, WeightState> {
  /// The [WeightRepository] backing data operations.
  final WeightRepository repository;
  StreamSubscription<List<WeightEntry>>? _entriesSubscription;

  /// Creates a [WeightBloc] backed by the given [repository].
  WeightBloc({required this.repository}) : super(const WeightInitial()) {
    on<SubscribeToWeightChanges>(_onSubscribeToWeightChanges);
    on<UpdateUserHeight>(_onUpdateUserHeight);
    on<AddWeight>(_onAddWeight);
    on<DeleteWeight>(_onDeleteWeight);
    on<ChangeChartFilter>(_onChangeChartFilter);
    on<RefreshWeightData>(_onRefreshWeightData);
  }

  List<WeightEntry> _filterEntries(
    List<WeightEntry> entries,
    TimePeriod period,
  ) {
    final filtered = switch (period) {
      TimePeriod.all => entries,
      TimePeriod.week =>
        entries
            .where(
              (e) => e.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              ),
            )
            .toList(),
      TimePeriod.month =>
        entries
            .where(
              (e) => e.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
            )
            .toList(),
      TimePeriod.year =>
        entries
            .where(
              (e) => e.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 365)),
              ),
            )
            .toList(),
    };
    return _aggregateByDay(filtered);
  }

  /// Aggregates [entries] so that multiple measurements on the same calendar
  /// day are collapsed into a single averaged data point.
  ///
  /// The merged entry carries the mean [WeightEntry.weightKg] and
  /// [WeightEntry.bmi] for that day, with [WeightEntry.dateTime] set to noon
  /// (12:00) of the day to keep the X-axis positions stable across re-renders.
  List<WeightEntry> _aggregateByDay(List<WeightEntry> entries) {
    if (entries.length <= 1) return entries;

    // Group by date (year-month-day)
    final Map<String, List<WeightEntry>> grouped = {};
    for (final e in entries) {
      final key = '${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return grouped.entries.map((group) {
      final dayEntries = group.value;
      final avgWeight =
          dayEntries.map((e) => e.weightKg).reduce((a, b) => a + b) /
          dayEntries.length;

      // Calculate average BMI from the averaged weight and the current
      // persisted user height stored in the bloc state. BMI is not stored
      // permanently in the DB so we compute it dynamically here so that
      // changes to height immediately reflect in aggregated values.

      // Use noon on that day as the canonical timestamp for stable X positions.
      final representative = dayEntries.first.dateTime;
      final noonDate = DateTime(
        representative.year,
        representative.month,
        representative.day,
        12,
      );
      return WeightEntry(
        id: dayEntries.first.id,
        weightKg: double.parse(avgWeight.toStringAsFixed(2)),
        dateTime: noonDate,
      );
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _onSubscribeToWeightChanges(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    // Cancel any existing subscription to avoid memory leaks
    await _entriesSubscription?.cancel();
    _entriesSubscription = null;

    // Emit loading state while establishing the new subscription.
    emit(WeightLoading(heightCm: state.heightCm, timePeriod: state.timePeriod));

    // Emit initial data synchronously to satisfy Bloc test expectations
    final initialEntries = await repository.watchAllEntries().first;
    if (!emit.isDone) {
      emit(
        WeightLoaded(
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: initialEntries,
          filteredEntries: _filterEntries(initialEntries, state.timePeriod),
        ),
      );
    }
    // Subscribe to subsequent updates without awaiting further emissions
    _entriesSubscription = repository
        .watchAllEntries()
        .skip(1)
        .listen(
          (entries) {
            if (!emit.isDone) {
              emit(
                WeightLoaded(
                  heightCm: state.heightCm,
                  timePeriod: state.timePeriod,
                  entries: entries,
                  filteredEntries: _filterEntries(entries, state.timePeriod),
                ),
              );
            }
          },
          onError: (error, stackTrace) {
            if (!emit.isDone) {
              emit(
                WeightError(
                  errorType: WeightErrorType.streamError,
                  heightCm: state.heightCm,
                  timePeriod: state.timePeriod,
                  entries: const [],
                  filteredEntries: const [],
                ),
              );
            }
          },
          cancelOnError: false,
        );
  }

  void _onUpdateUserHeight(UpdateUserHeight event, Emitter<WeightState> emit) {
    final entries = switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
    emit(
      WeightLoaded(
        heightCm: event.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: _filterEntries(entries, state.timePeriod),
      ),
    );
  }

  Future<void> _onAddWeight(AddWeight event, Emitter<WeightState> emit) async {
    final heightCm = state.heightCm;
    final entries = switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };

    if (heightCm == null || heightCm <= 0) {
      emit(
        WeightError(
          errorType: WeightErrorType.heightNotSet,
          message: 'Set your height first.',
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
      return;
    }

    final entry = WeightEntry(
      weightKg: event.weightKg,
      dateTime: DateTime.now(),
      note: event.note,
    );

    try {
      await repository.addEntry(entry);
    } catch (e) {
      emit(
        WeightError(
          errorType: WeightErrorType.addEntryFailed,
          message: 'Failed to add entry: $e',
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  Future<void> _onDeleteWeight(
    DeleteWeight event,
    Emitter<WeightState> emit,
  ) async {
    try {
      await repository.deleteEntry(event.id);
    } catch (e) {
      final entries = switch (state) {
        WeightLoaded(:final entries) => entries,
        WeightError(:final entries) => entries,
        _ => <WeightEntry>[],
      };
      emit(
        WeightError(
          errorType: WeightErrorType.deleteEntryFailed,
          message: 'Failed to delete entry: $e',
          heightCm: state.heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
    }
  }

  void _onChangeChartFilter(
    ChangeChartFilter event,
    Emitter<WeightState> emit,
  ) {
    final entries = switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };

    emit(
      WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: event.period,
        entries: entries,
        filteredEntries: _filterEntries(entries, event.period),
      ),
    );
  }

  Future<void> _onRefreshWeightData(
    RefreshWeightData event,
    Emitter<WeightState> emit,
  ) async {
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
  }

  // Holds the active repository subscription for weight entries.

  @override
  Future<void> close() async {
    await _entriesSubscription?.cancel();
    return super.close();
  }

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
      heightCm: json['heightCm'] as double?,
      timePeriod: period,
    );
  }

  @override
  Map<String, dynamic>? toJson(WeightState state) {
    return {'heightCm': state.heightCm, 'timePeriod': state.timePeriod.name};
  }
}
