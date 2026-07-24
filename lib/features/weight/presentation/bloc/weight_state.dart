import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';

/// Possible states of [WeightBloc].
sealed class WeightState {
  /// User's height in cm, persisted via HydratedBloc.
  final double? heightCm;
  const WeightState({this.heightCm});
}

/// Initial state before any subscription or interaction.
final class WeightInitial extends WeightState {
  /// Creates [WeightInitial] with an optional persisted [heightCm].
  const WeightInitial({super.heightCm});
}

/// Transitional state while subscribing to the reactive stream.
final class WeightLoading extends WeightState {
  /// Creates [WeightLoading] with an optional [heightCm].
  const WeightLoading({super.heightCm});
}

/// Steady state with a list of entries and optional height.
final class WeightLoaded extends WeightState {
  /// All stored weight entries.
  final List<WeightEntry> entries;

  /// Creates [WeightLoaded] with the given [entries] and optional [heightCm].
  const WeightLoaded({super.heightCm, required this.entries});
}

/// Error state with a descriptive [message] and last known [entries].
final class WeightError extends WeightState {
  /// Human-readable error description.
  final String message;

  /// Last known entries preserved for display.
  final List<WeightEntry> entries;

  /// Creates [WeightError] with [message], [entries], and optional [heightCm].
  const WeightError({
    super.heightCm,
    required this.message,
    required this.entries,
  });
}
