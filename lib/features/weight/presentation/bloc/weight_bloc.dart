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
  }

  Future<void> _onSubscribeToWeightChanges(
    SubscribeToWeightChanges event,
    Emitter<WeightState> emit,
  ) async {
    emit(WeightLoading(heightCm: state.heightCm));
    await emit.forEach<List<WeightEntry>>(
      repository.watchAllEntries(),
      onData: (entries) =>
          WeightLoaded(heightCm: state.heightCm, entries: entries),
      onError: (error, _) => WeightError(
        message: error.toString(),
        heightCm: state.heightCm,
        entries: const [],
      ),
    );
  }

  void _onUpdateUserHeight(UpdateUserHeight event, Emitter<WeightState> emit) {
    final entries = switch (state) {
      WeightLoaded(:final entries) => entries,
      WeightError(:final entries) => entries,
      _ => <WeightEntry>[],
    };
    emit(WeightLoaded(heightCm: event.heightCm, entries: entries));
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
          entries: entries,
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
          entries: entries,
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
          entries: entries,
        ),
      );
    }
  }

  @override
  WeightState? fromJson(Map<String, dynamic> json) {
    return WeightInitial(heightCm: json['heightCm'] as double?);
  }

  @override
  Map<String, dynamic>? toJson(WeightState state) {
    return {'heightCm': state.heightCm};
  }
}
