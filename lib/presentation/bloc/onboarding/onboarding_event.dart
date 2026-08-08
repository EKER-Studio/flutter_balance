import 'package:equatable/equatable.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Base class for all onboarding wizard events.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => const [];
}

/// Initializes (or resets) the wizard to its starting state.
final class OnboardingStarted extends OnboardingEvent {
  /// Creates [OnboardingStarted].
  const OnboardingStarted();
}

/// Advances the wizard to the next step.
final class OnboardingStepAdvanced extends OnboardingEvent {
  /// Creates [OnboardingStepAdvanced].
  const OnboardingStepAdvanced();
}

/// Rewinds the wizard to the previous step.
final class OnboardingStepRewound extends OnboardingEvent {
  /// Creates [OnboardingStepRewound].
  const OnboardingStepRewound();
}

/// Updates the measurement unit selected on the units & height step.
final class OnboardingUnitSelected extends OnboardingEvent {
  /// The newly selected unit system.
  final MeasurementUnit unit;

  /// Creates [OnboardingUnitSelected].
  ///
  /// @param unit The newly selected unit system.
  const OnboardingUnitSelected(this.unit);

  @override
  List<Object?> get props => [unit];
}

/// Stores the history parsed by the CSV import step.
final class OnboardingCsvImported extends OnboardingEvent {
  /// Parsed entries to keep as draft data for the wizard.
  final List<WeightEntry> entries;

  /// Creates [OnboardingCsvImported].
  ///
  /// @param entries Parsed entries to keep as draft data for the wizard.
  const OnboardingCsvImported(this.entries);

  @override
  List<Object?> get props => [entries];
}

/// Updates the draft initial weight (and its optional timestamp).
final class OnboardingInitialWeightSet extends OnboardingEvent {
  /// Initial weight in kilograms.
  final double weightKg;

  /// Timestamp of the measurement, or `null` to default to now.
  final DateTime? timestamp;

  /// Creates [OnboardingInitialWeightSet].
  ///
  /// @param weightKg Initial weight in kilograms.
  /// @param timestamp Timestamp of the measurement, or `null` to default to now.
  const OnboardingInitialWeightSet({required this.weightKg, this.timestamp});

  @override
  List<Object?> get props => [weightKg, timestamp];
}

/// Updates the draft target weight (`null` clears it when the step is skipped).
final class OnboardingTargetWeightSet extends OnboardingEvent {
  /// Target weight in kilograms, or `null` when no target was set.
  final double? weightKg;

  /// Creates [OnboardingTargetWeightSet].
  ///
  /// @param weightKg Target weight in kilograms, or `null` when no target was set.
  const OnboardingTargetWeightSet(this.weightKg);

  @override
  List<Object?> get props => [weightKg];
}

/// Records whether the user connected health sync during onboarding.
final class OnboardingHealthSyncToggled extends OnboardingEvent {
  /// Whether health sync was requested.
  final bool enabled;

  /// Creates [OnboardingHealthSyncToggled].
  ///
  /// @param enabled Whether health sync was requested.
  const OnboardingHealthSyncToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Records whether the user enabled the biometric lock during onboarding.
final class OnboardingBiometricsToggled extends OnboardingEvent {
  /// Whether the biometric lock was enabled.
  final bool enabled;

  /// Creates [OnboardingBiometricsToggled].
  ///
  /// @param enabled Whether the biometric lock was enabled.
  const OnboardingBiometricsToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Performs the final persistence of the wizard's draft data.
final class OnboardingCompleted extends OnboardingEvent {
  /// Creates [OnboardingCompleted].
  const OnboardingCompleted();
}
