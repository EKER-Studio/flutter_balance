import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';

export 'package:balance/features/weight/domain/time_period.dart';

/// Base class for all weight events.
sealed class WeightEvent {
  const WeightEvent();
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

  /// Optional custom timestamp for the measurement (defaults to current date/time if null).
  final DateTime? dateTime;

  /// Creates [AddWeight] with the given [weightKg], optional [note], and optional [dateTime].
  const AddWeight({required this.weightKg, this.note, this.dateTime});
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

/// Clears all weight entries from the database.
final class ClearAllWeightData extends WeightEvent {
  /// Creates [ClearAllWeightData].
  const ClearAllWeightData();
}

/// Bulk imports weight entries into the database.
final class ImportWeightEntries extends WeightEvent {
  /// Entries to import.
  final List<WeightEntry> entries;

  /// Creates [ImportWeightEntries] with the given [entries].
  const ImportWeightEntries(this.entries);
}

/// Pulls weight history from HealthKit / Health Connect and merges records
/// that do not already exist locally.
///
/// The pull is best-effort: it aborts silently when health sync is disabled
/// or the platform errors out, so the local database and UI are never blocked.
///
/// The window starts at [startDate] (or the trailing 30 days when it is
/// `null`) and ends at the present.
final class SyncHealthEntries extends WeightEvent {
  /// Start of the sync window; `null` defaults to the last 30 days.
  final DateTime? startDate;

  /// Creates [SyncHealthEntries] with the given [startDate].
  ///
  /// @param startDate Start of the sync window, or `null` to default to the
  ///   last 30 days.
  const SyncHealthEntries({this.startDate});
}
