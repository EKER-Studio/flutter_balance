import 'package:balance/core/integrations/csv/csv_importer.dart';
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
  final double heightCm;

  const UpdateUserHeight(this.heightCm);
}

/// An event that adds a new weight measurement; BMI is auto-calculated from
/// stored height.
final class AddWeight extends WeightEvent {
  final double weightKg;
  final String? note;
  final DateTime? dateTime;

  const AddWeight({required this.weightKg, this.note, this.dateTime});
}

/// An event that updates an existing weight measurement in the repository.
final class UpdateWeight extends WeightEvent {
  /// The updated weight entry containing a persisted ID.
  final WeightEntry entry;

  const UpdateWeight(this.entry);
}

/// An event that removes the entry with the given [id].
final class DeleteWeight extends WeightEvent {
  final int id;

  const DeleteWeight(this.id);
}

/// An event that changes the active time filter for the weight chart.
final class ChangeChartFilter extends WeightEvent {
  final TimePeriod period;

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
  final List<WeightEntry> entries;

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
  final DateTime? startDate;

  const SyncHealthEntries({this.startDate});
}

/// Triggers a dry-run analysis of the CSV file at [filePath] without writing
/// to the database.
///
/// On success, the BLoC emits [CsvAnalysisReady] carrying the
/// [CsvImportAnalysis] summary for the preview dialog.
/// On failure it emits [CsvAnalysisError] with a typed [CsvErrorType].
final class AnalyzeCsvFile extends WeightEvent {
  final String filePath;

  const AnalyzeCsvFile({required this.filePath});
}

/// Confirms the import of [validEntries] previously returned by [AnalyzeCsvFile].
///
/// Writes the entries to the database via an idempotent bulk transaction and
/// emits [WeightImportSuccess] with the count of newly inserted records.
final class ConfirmCsvImport extends WeightEvent {
  final List<WeightEntry> validEntries;

  const ConfirmCsvImport({required this.validEntries});
}
