export 'package:balance/features/weight/domain/csv_error_type.dart';

import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:balance/features/weight/domain/csv_error_type.dart';
import 'package:balance/features/weight/domain/entities/csv_import_analysis.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

/// The possible states of [WeightBloc].
sealed class WeightState extends Equatable {
  final double? heightCm;
  final TimePeriod timePeriod;
  final List<WeightEntry> _entries;
  final List<WeightEntry> _filteredEntries;

  WeightState({
    this.heightCm,
    this.timePeriod = TimePeriod.week,
    List<WeightEntry> entries = const [],
    List<WeightEntry> filteredEntries = const [],
  }) : _entries = _freezeEntries(entries),
       _filteredEntries = _freezeEntries(filteredEntries);

  static List<WeightEntry> _freezeEntries(List<WeightEntry> entries) =>
      entries is UnmodifiableListView<WeightEntry>
      ? entries
      : List<WeightEntry>.unmodifiable(entries);

  /// Read-only view of the complete entry collection.
  List<WeightEntry> get entries {
    final entries = _entries;
    return entries is UnmodifiableListView<WeightEntry>
        ? entries
        : UnmodifiableListView(entries);
  }

  /// Read-only view of the entries filtered for the active chart period.
  List<WeightEntry> get filteredEntries {
    final filteredEntries = _filteredEntries;
    return filteredEntries is UnmodifiableListView<WeightEntry>
        ? filteredEntries
        : UnmodifiableListView(filteredEntries);
  }

  @override
  List<Object?> get props => [heightCm, timePeriod, entries, filteredEntries];
}

/// The initial state before any subscription or interaction.
final class WeightInitial extends WeightState {
  WeightInitial({
    super.heightCm,
    super.timePeriod,
    super.entries,
    super.filteredEntries,
  });
}

/// A transitional state while subscribing to the reactive stream.
final class WeightLoading extends WeightState {
  WeightLoading({
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
  WeightLoaded({
    super.heightCm,
    super.timePeriod,
    required super.entries,
    required super.filteredEntries,
  });
}

/// An error state with a typed [errorType] and last known [entries].
final class WeightError extends WeightState {
  final WeightErrorType errorType;

  WeightError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required super.entries,
    required super.filteredEntries,
  });

  @override
  List<Object?> get props => [...super.props, errorType];
}

/// Transient state emitted while the CSV file is being parsed on the isolate.
final class CsvAnalysisInProgress extends WeightState {
  CsvAnalysisInProgress({
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

  CsvAnalysisReady({
    super.heightCm,
    super.timePeriod,
    required super.entries,
    required super.filteredEntries,
    required this.analysis,
  });

  @override
  List<Object?> get props => [...super.props, analysis];
}

/// Transient success state emitted immediately after a confirmed CSV import,
/// before the reactive Isar stream delivers the updated entry list.
final class WeightImportSuccess extends WeightState {
  /// The number of new records inserted (duplicate entries are excluded).
  final int importedCount;

  WeightImportSuccess({
    super.heightCm,
    super.timePeriod,
    required this.importedCount,
    required super.entries,
    required super.filteredEntries,
  });

  @override
  List<Object?> get props => [...super.props, importedCount];
}

/// Error state specific to CSV file analysis; never replaces [WeightError].
final class CsvAnalysisError extends WeightState {
  final CsvErrorType errorType;

  CsvAnalysisError({
    super.heightCm,
    super.timePeriod,
    required this.errorType,
    required super.entries,
    required super.filteredEntries,
  });

  @override
  List<Object?> get props => [...super.props, errorType];
}
