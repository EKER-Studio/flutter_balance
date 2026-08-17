
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// The possible states of [WeightBloc].
sealed class WeightState {
  /// The user's height in cm, persisted via HydratedBloc.
  final double? heightCm;

  /// The currently selected time period for the chart.
  final TimePeriod timePeriod;

  /// Creates a [WeightState] with the given parameters.
  ///
  /// @param heightCm User's height in cm, persisted via HydratedBloc.
  /// @param timePeriod Currently selected time period for the chart, defaults to [TimePeriod.week].
  const WeightState({this.heightCm, this.timePeriod = TimePeriod.week});
}

/// The initial state before any subscription or interaction.
final class WeightInitial extends WeightState {
  /// Creates [WeightInitial] with an optional persisted [heightCm].
  const WeightInitial({super.heightCm, super.timePeriod});
}

/// A transitional state while subscribing to the reactive stream.
final class WeightLoading extends WeightState {
  /// Creates [WeightLoading] with an optional [heightCm].
  const WeightLoading({super.heightCm, super.timePeriod});
}

/// A steady state with a list of entries and optional height.
///
/// Also emitted after a [SyncHealthEntries] pull merges remote records into
/// the local database, exposing the refreshed dataset to the UI.
final class WeightLoaded extends WeightState {
  /// All stored weight entries.
  final List<WeightEntry> entries;

  /// Entries filtered by the current [timePeriod].
  final List<WeightEntry> filteredEntries;

  /// Creates [WeightLoaded] with the given parameters.
  ///
  /// @param entries All stored weight entries.
  /// @param filteredEntries Entries filtered by the current [timePeriod].
  const WeightLoaded({
    super.heightCm,
    super.timePeriod,
    required this.entries,
    required this.filteredEntries,
  });
}

/// An error state with a typed [errorType] and last known [entries].
final class WeightError extends WeightState {
  /// The reason for the error.
  final WeightErrorType errorType;

  /// Last known entries preserved for display.
  final List<WeightEntry> entries;

  /// Last known filtered entries preserved for display.
  final List<WeightEntry> filteredEntries;

  /// Creates [WeightError] with the given parameters.
  ///
  /// @param errorType The reason for the error.
  /// @param entries Last known entries preserved for display.
  /// @param filteredEntries Last known filtered entries preserved for display.
  const WeightError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required this.entries,
    required this.filteredEntries,
  });
}
