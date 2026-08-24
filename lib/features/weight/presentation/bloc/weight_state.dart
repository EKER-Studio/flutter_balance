export 'package:balance/features/weight/domain/csv_error_type.dart';

import 'package:balance/core/integrations/csv/csv_importer.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// The possible states of [WeightBloc].
sealed class WeightState {
  final double? heightCm;
  final TimePeriod timePeriod;
  final List<WeightEntry> entries;
  final List<WeightEntry> filteredEntries;

  const WeightState({
    this.heightCm,
    this.timePeriod = TimePeriod.week,
    this.entries = const [],
    this.filteredEntries = const [],
  });
}

/// The initial state before any subscription or interaction.
final class WeightInitial extends WeightState {
  const WeightInitial({
    super.heightCm,
    super.timePeriod,
    super.entries,
    super.filteredEntries,
  });
}

/// A transitional state while subscribing to the reactive stream.
final class WeightLoading extends WeightState {
  const WeightLoading({
    super.heightCm,
    super.timePeriod,
    super.entries,
    super.filteredEntries,
  });
}

/// A steady state with a list of entries and optional height.
///
/// Also emitted after a [SyncHealthEntries] pull merges remote records into
/// the local database, exposing the refreshed dataset to the UI.
final class WeightLoaded extends WeightState {
  const WeightLoaded({
    super.heightCm,
    super.timePeriod,
    required super.entries,
    required super.filteredEntries,
  });
}

/// An error state with a typed [errorType] and last known [entries].
final class WeightError extends WeightState {
  final WeightErrorType errorType;

  const WeightError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required super.entries,
    required super.filteredEntries,
  });
}

/// Transient state emitted while the CSV file is being parsed on the isolate.
final class CsvAnalysisInProgress extends WeightState {
  const CsvAnalysisInProgress({
    super.heightCm,
    super.timePeriod,
    required super.entries,
    required super.filteredEntries,
  });
}

/// Transient state carrying the [CsvImportAnalysis] result for the preview dialog.
final class CsvAnalysisReady extends WeightState {
  /// The parsed analysis result containing valid entries and audit statistics.
  final CsvImportAnalysis analysis;

  const CsvAnalysisReady({
    super.heightCm,
    super.timePeriod,
    required super.entries,
    required super.filteredEntries,
    required this.analysis,
  });
}

/// Transient success state emitted immediately after a confirmed CSV import,
/// before the reactive Isar stream delivers the updated entry list.
final class WeightImportSuccess extends WeightState {
  /// The number of new records inserted (duplicate entries are excluded).
  final int importedCount;

  const WeightImportSuccess({
    super.heightCm,
    super.timePeriod,
    required this.importedCount,
    required super.entries,
    required super.filteredEntries,
  });
}

/// Error state specific to CSV file analysis; never replaces [WeightError].
final class CsvAnalysisError extends WeightState {
  final CsvErrorType errorType;

  const CsvAnalysisError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required super.entries,
    required super.filteredEntries,
  });
}
