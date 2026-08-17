import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';

export 'package:balance/features/weight/domain/time_period.dart';

/// A base class for all weight events.
sealed class WeightEvent {
  const WeightEvent();
}

/// An event that triggers subscription to the reactive weight stream.
final class SubscribeToWeightChanges extends WeightEvent {
  const SubscribeToWeightChanges();
}

/// An event that updates the user's height (in cm), persisted via HydratedBloc.
final class UpdateUserHeight extends WeightEvent {
  /// Height in centimetres.
  final double heightCm;

  /// Creates [UpdateUserHeight] with the given [heightCm].
  const UpdateUserHeight(this.heightCm);
}

/// An event that adds a new weight measurement; BMI is auto-calculated from
/// stored height.
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

/// An event that removes the entry with the given [id].
final class DeleteWeight extends WeightEvent {
  /// Identifier of the entry to remove.
  final int id;

  /// Creates [DeleteWeight] targeting [id].
  const DeleteWeight(this.id);
}

/// An event that changes the active time filter for the weight chart.
final class ChangeChartFilter extends WeightEvent {
  /// The newly selected time period.
  final TimePeriod period;

  /// Creates [ChangeChartFilter] with the given [period].
  const ChangeChartFilter(this.period);
}

/// An event that requests a fresh read of all weight entries from the
/// repository.
///
/// Useful after external data mutations (e.g. CSV import) to ensure the
/// UI reflects the latest database state.
final class RefreshWeightData extends WeightEvent {
  const RefreshWeightData();
}

/// An event that clears all weight entries from the database.
final class ClearAllWeightData extends WeightEvent {
  const ClearAllWeightData();
}

/// An event that bulk imports weight entries into the database.
final class ImportWeightEntries extends WeightEvent {
  /// Entries to import.
  final List<WeightEntry> entries;

  /// Creates [ImportWeightEntries] with the given [entries].
  const ImportWeightEntries(this.entries);
}

/// An event that pulls weight history from HealthKit / Health Connect and
/// merges records that do not already exist locally.
///
/// The pull is best-effort: it aborts silently when health sync is disabled
/// or the platform errors out, so the local database and UI are never blocked.
///
/// The window starts at [startDate] (or the deep past when it is `null`,
/// so historical records are never missed) and ends at the present.
final class SyncHealthEntries extends WeightEvent {
  /// Start of the sync window; `null` defaults to the deep past.
  final DateTime? startDate;

  /// Creates [SyncHealthEntries] with the given [startDate].
  const SyncHealthEntries({this.startDate});
}
