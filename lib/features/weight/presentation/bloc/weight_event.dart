/// Events dispatched to [WeightBloc].
sealed class WeightEvent {
  const WeightEvent();
}

/// Defines the selected time period for the chart filter.
enum TimePeriod {
  /// Last 7 days.
  week,

  /// Last 30 days.
  month,

  /// Last 365 days.
  year,

  /// All time.
  all,
}

/// Triggers subscription to the reactive weight stream.
final class SubscribeToWeightChanges extends WeightEvent {
  /// Creates [SubscribeToWeightChanges].
  const SubscribeToWeightChanges();
}

/// Updates the user's height (in cm), persisted via HydratedBloc.
final class UpdateUserHeight extends WeightEvent {
  /// Height in centimetres.
  final double heightCm;

  /// Creates [UpdateUserHeight] with the given [heightCm].
  const UpdateUserHeight(this.heightCm);
}

/// Adds a new weight measurement; BMI is auto-calculated from stored height.
final class AddWeight extends WeightEvent {
  /// Weight in kilograms.
  final double weightKg;

  /// Optional note attached to this measurement.
  final String? note;

  /// Creates [AddWeight] with the given [weightKg] and optional [note].
  const AddWeight({required this.weightKg, this.note});
}

/// Removes the entry with the given [id].
final class DeleteWeight extends WeightEvent {
  /// Identifier of the entry to remove.
  final int id;

  /// Creates [DeleteWeight] targeting [id].
  const DeleteWeight(this.id);
}

/// Changes the active time filter for the weight chart.
final class ChangeChartFilter extends WeightEvent {
  /// The newly selected time period.
  final TimePeriod period;

  /// Creates [ChangeChartFilter] with the given [period].
  const ChangeChartFilter(this.period);
}

/// Requests a fresh read of all weight entries from the repository.
///
/// Useful after external data mutations (e.g. CSV import) to ensure the
/// UI reflects the latest database state.
final class RefreshWeightData extends WeightEvent {
  /// Creates [RefreshWeightData].
  const RefreshWeightData();
}
