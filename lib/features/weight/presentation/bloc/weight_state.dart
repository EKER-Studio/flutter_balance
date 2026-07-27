import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';

/// Possible states of [WeightBloc].
sealed class WeightState {
  /// User's height in cm, persisted via HydratedBloc.
  final double? heightCm;

  /// Currently selected time period for the chart.
  final TimePeriod timePeriod;

  const WeightState({this.heightCm, this.timePeriod = TimePeriod.week});
}

/// Initial state before any subscription or interaction.
final class WeightInitial extends WeightState {
  /// Creates [WeightInitial] with an optional persisted [heightCm].
  const WeightInitial({super.heightCm, super.timePeriod});
}

/// Transitional state while subscribing to the reactive stream.
final class WeightLoading extends WeightState {
  /// Creates [WeightLoading] with an optional [heightCm].
  const WeightLoading({super.heightCm, super.timePeriod});
}

/// Steady state with a list of entries and optional height.
final class WeightLoaded extends WeightState {
  /// All stored weight entries.
  final List<WeightEntry> entries;

  /// Entries filtered by the current [timePeriod].
  final List<WeightEntry> filteredEntries;

  /// Creates [WeightLoaded] with the given [entries] and optional [heightCm].
  const WeightLoaded({
    super.heightCm,
    super.timePeriod,
    required this.entries,
    required this.filteredEntries,
  });
}

/// Error state with a typed [errorType] and last known [entries].
final class WeightError extends WeightState {
  /// The reason for the error.
  final WeightErrorType errorType;

  /// Last known entries preserved for display.
  final List<WeightEntry> entries;

  /// Last known filtered entries preserved for display.
  final List<WeightEntry> filteredEntries;

  /// Creates [WeightError] with [errorType], [entries], and optional [heightCm].
  const WeightError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required this.entries,
    required this.filteredEntries,
  });
}
