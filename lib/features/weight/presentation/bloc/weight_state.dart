import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// The possible states of [WeightBloc].
sealed class WeightState {
  /// The user's height in cm, persisted via HydratedBloc.
  final double? heightCm;

  /// The currently selected time period for the chart.
  final TimePeriod timePeriod;

  /// Creates a [WeightState] with optional [heightCm] and [timePeriod] (defaults to [TimePeriod.week]).
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

  /// Creates [WeightLoaded] with [entries] and [filteredEntries].
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

  /// Creates [WeightError] with [errorType], [entries], and [filteredEntries].
  const WeightError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required this.entries,
    required this.filteredEntries,
  });
}

/// Categorizes failures specific to CSV file analysis.
enum CsvErrorType {
  /// The selected file exceeds the 5 MB size limit.
  fileTooLarge,

  /// No valid date and weight columns were found in the file.
  invalidFormat,

  /// The file parsed successfully but contained no valid measurements.
  noEntries,
}

/// Transient state emitted while the CSV file is being parsed on the isolate.
final class CsvAnalysisInProgress extends WeightState {
  /// Last known weight entries, preserved so the UI keeps displaying data.
  final List<WeightEntry> entries;

  /// Last known filtered entries.
  final List<WeightEntry> filteredEntries;

  /// Creates [CsvAnalysisInProgress] preserving [entries] and [filteredEntries].
  const CsvAnalysisInProgress({
    super.heightCm,
    super.timePeriod,
    required this.entries,
    required this.filteredEntries,
  });
}

/// Transient state carrying the [CsvImportAnalysis] result for the preview dialog.
final class CsvAnalysisReady extends WeightState {
  /// Last known weight entries, preserved so the UI keeps displaying data.
  final List<WeightEntry> entries;

  /// Last known filtered entries.
  final List<WeightEntry> filteredEntries;

  /// The parsed analysis result containing valid entries and audit statistics.
  final CsvImportAnalysis analysis;

  /// Creates [CsvAnalysisReady] with [analysis] and preserved [entries].
  const CsvAnalysisReady({
    super.heightCm,
    super.timePeriod,
    required this.entries,
    required this.filteredEntries,
    required this.analysis,
  });
}

/// Transient success state emitted immediately after a confirmed CSV import,
/// before the reactive Isar stream delivers the updated entry list.
final class WeightImportSuccess extends WeightState {
  /// The number of new records inserted (duplicate entries are excluded).
  final int importedCount;

  /// Updated weight entries after the import.
  final List<WeightEntry> entries;

  /// Updated filtered entries after the import.
  final List<WeightEntry> filteredEntries;

  /// Creates [WeightImportSuccess] with [importedCount] and updated [entries].
  const WeightImportSuccess({
    super.heightCm,
    super.timePeriod,
    required this.importedCount,
    required this.entries,
    required this.filteredEntries,
  });
}

/// Error state specific to CSV file analysis; never replaces [WeightError].
final class CsvAnalysisError extends WeightState {
  /// The reason the CSV analysis failed.
  final CsvErrorType errorType;

  /// Last known weight entries, preserved so the UI keeps displaying data.
  final List<WeightEntry> entries;

  /// Last known filtered entries.
  final List<WeightEntry> filteredEntries;

  /// Creates [CsvAnalysisError] with [errorType] and preserved [entries].
  const CsvAnalysisError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required this.entries,
    required this.filteredEntries,
  });
}
