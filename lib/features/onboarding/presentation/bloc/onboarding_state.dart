
import 'package:equatable/equatable.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Ephemeral state of the onboarding wizard.
///
/// Holds only temporary wizard data (current step, draft weights, imported
/// CSV entries, toggled integration flags). Persistent settings continue to
/// live in `AppSettingsState`; nothing here is stored across restarts.
final class OnboardingState extends Equatable {
  static const Object _sentinel = Object();

  /// Index of the currently displayed step (0-based).
  final int currentStepIndex;

  /// Total number of steps in the current build; differs on devices without
  /// biometric credential support.
  final int totalSteps;

  /// Measurement unit system selected during onboarding.
  final MeasurementUnit selectedUnit;

  /// History parsed from the CSV import step, not yet persisted.
  final List<WeightEntry> importedCsvEntries;

  /// Initial weight in kg confirmed on the initial-weight step.
  final double? draftInitialWeight;

  /// Timestamp of the confirmed [draftInitialWeight].
  final DateTime? draftInitialTimestamp;

  /// Target weight in kg confirmed on the target-weight step (`null` when skipped).
  final double? draftTargetWeight;

  /// Whether the user connected health sync during onboarding.
  final bool isHealthSyncRequested;

  /// Whether the user enabled the biometric lock during onboarding.
  final bool isBiometricEnabled;

  /// Creates an [OnboardingState] with the given parameters.
  ///
  /// @param currentStepIndex Index of the currently displayed step (0-based), defaults to 0.
  /// @param totalSteps Total step count, defaults to 6; differs on devices without biometric credential support.
  /// @param selectedUnit Measurement unit system selected during onboarding.
  /// @param importedCsvEntries History parsed from the CSV import step, not yet persisted.
  /// @param draftInitialWeight Initial weight in kg confirmed on the initial-weight step.
  /// @param draftInitialTimestamp Timestamp of the confirmed [draftInitialWeight].
  /// @param draftTargetWeight Target weight in kg confirmed on the target-weight step (`null` when skipped).
  /// @param isHealthSyncRequested Whether the user connected health sync during onboarding.
  /// @param isBiometricEnabled Whether the user enabled the biometric lock during onboarding.
  const OnboardingState({
    this.currentStepIndex = 0,
    this.totalSteps = 6,
    this.selectedUnit = MeasurementUnit.metric,
    this.importedCsvEntries = const [],
    this.draftInitialWeight,
    this.draftInitialTimestamp,
    this.draftTargetWeight,
    this.isHealthSyncRequested = false,
    this.isBiometricEnabled = false,
  });

  /// Latest chronological entry from [importedCsvEntries], or `null` when
  /// nothing was imported.
  ///
  /// Used both to pre-fill the initial-weight step and to exclude that entry
  /// from the bulk import on completion (it is persisted separately via
  /// [draftInitialWeight]).
  WeightEntry? get latestImportedEntry {
    if (importedCsvEntries.isEmpty) return null;
    return importedCsvEntries.reduce(
      (a, b) => a.dateTime.isAfter(b.dateTime) ? a : b,
    );
  }

  /// Creates a copy of this state with the given fields replaced.
  ///
  /// Nullable draft fields use a sentinel default so `null` can be written
  /// back explicitly.
  ///
  /// @param draftInitialWeight Replaces [draftInitialWeight]; pass `null` to clear it.
  /// @param draftInitialTimestamp Replaces [draftInitialTimestamp]; pass `null` to clear it.
  /// @param draftTargetWeight Replaces [draftTargetWeight]; pass `null` to clear it.
  OnboardingState copyWith({
    int? currentStepIndex,
    int? totalSteps,
    MeasurementUnit? selectedUnit,
    List<WeightEntry>? importedCsvEntries,
    Object? draftInitialWeight = _sentinel,
    Object? draftInitialTimestamp = _sentinel,
    Object? draftTargetWeight = _sentinel,
    bool? isHealthSyncRequested,
    bool? isBiometricEnabled,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      importedCsvEntries: importedCsvEntries ?? this.importedCsvEntries,
      draftInitialWeight: draftInitialWeight == _sentinel
          ? this.draftInitialWeight
          : draftInitialWeight as double?,
      draftInitialTimestamp: draftInitialTimestamp == _sentinel
          ? this.draftInitialTimestamp
          : draftInitialTimestamp as DateTime?,
      draftTargetWeight: draftTargetWeight == _sentinel
          ? this.draftTargetWeight
          : draftTargetWeight as double?,
      isHealthSyncRequested:
          isHealthSyncRequested ?? this.isHealthSyncRequested,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }

  @override
  List<Object?> get props => [
    currentStepIndex,
    totalSteps,
    selectedUnit,
    importedCsvEntries,
    draftInitialWeight,
    draftInitialTimestamp,
    draftTargetWeight,
    isHealthSyncRequested,
    isBiometricEnabled,
  ];
}
