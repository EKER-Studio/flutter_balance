import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';

/// BLoC managing weight entries and user height.
///
/// Uses [HydratedBloc] to persist [WeightState.heightCm] across restarts.
class WeightBloc extends HydratedBloc<WeightEvent, WeightState> {
  /// The [WeightRepository] backing data operations.
  final WeightRepository repository;

  /// Creates a [WeightBloc] backed by the given [repository].
  WeightBloc({required this.repository}) : super(const WeightInitial()) {
    on<SubscribeToWeightChanges>(_onSubscribeToWeightChanges);
    on<UpdateUserHeight>(_onUpdateUserHeight);
    on<AddWeight>(_onAddWeight);
    on<DeleteWeight>(_onDeleteWeight);
    on<ChangeChartFilter>(_onChangeChartFilter);
  }

  List<WeightEntry> _filterEntries(
    List<WeightEntry> entries,
    TimePeriod period,
  ) {
    if (period == TimePeriod.all) return entries;
    final now = DateTime.now();
    final limit = switch (period) {
      TimePeriod.week => now.subtract(const Duration(days: 7)),
      TimePeriod.month => now.subtract(const Duration(days: 30)),
      TimePeriod.year => now.subtract(const Duration(days: 365)),
      TimePeriod.all => now,
    };
    return entries.where((e) => e.dateTime.isAfter(limit)).toList();
  }

  Future<void> _onSubscribeToWeightChanges(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    emit(WeightLoading(heightCm: state.heightCm, timePeriod: state.timePeriod));
    await emit.forEach<List<WeightEntry>>(
      repository.watchAllEntries(),
      onData: (entries) => WeightLoaded(
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: entries,
        filteredEntries: _filterEntries(entries, state.timePeriod),
      ),
      onError: (error, _) => WeightError(
        message: error.toString(),
        heightCm: state.heightCm,
        timePeriod: state.timePeriod,
        entries: const [],
        filteredEntries: const [],
      ),
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
          message: 'Set your height first.',
          heightCm: heightCm,
          timePeriod: state.timePeriod,
          entries: entries,
          filteredEntries: _filterEntries(entries, state.timePeriod),
        ),
      );
      return;
    }

    final heightM = heightCm / 100.0;
    final entry = WeightEntry.withBmi(
      weightKg: event.weightKg,
      heightMeters: heightM,
      dateTime: DateTime.now(),
      note: event.note,
    );

    try {
      await repository.addEntry(entry);
    } catch (e) {
      emit(
        WeightError(
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
