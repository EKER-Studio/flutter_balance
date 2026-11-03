import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Derives the persistence actions required to finish onboarding.
final class OnboardingCompletionPlan {
  final List<WeightEntry> entriesToImport;
  final bool enableHealthSync;
  final bool enableBiometricLock;

  OnboardingCompletionPlan._({
    required List<WeightEntry> entriesToImport,
    required this.enableHealthSync,
    required this.enableBiometricLock,
  }) : entriesToImport = List.unmodifiable(entriesToImport);

  /// Builds a completion plan from the wizard draft and current settings.
  ///
  /// [importedEntries] are the rows parsed from the selected CSV.
  /// [healthSyncRequested] and [biometricLockRequested] are the wizard choices.
  /// [healthSyncEnabled] and [biometricLockEnabled] are the persisted choices.
  /// [now] may be supplied to make date selection deterministic in tests.
  factory OnboardingCompletionPlan.fromDraft({
    required List<WeightEntry> importedEntries,
    required bool healthSyncRequested,
    required bool biometricLockRequested,
    required bool healthSyncEnabled,
    required bool biometricLockEnabled,
    DateTime? now,
  }) {
    final latestEntry = latestImportedEntry(importedEntries, now: now);
    final entriesToImport = latestEntry == null
        ? const <WeightEntry>[]
        : importedEntries.where((entry) => entry != latestEntry).toList();

    return OnboardingCompletionPlan._(
      entriesToImport: entriesToImport,
      enableHealthSync: healthSyncRequested && !healthSyncEnabled,
      enableBiometricLock: biometricLockRequested && !biometricLockEnabled,
    );
  }

  /// Selects today's latest entry, or the latest historical entry if none are from today.
  static WeightEntry? latestImportedEntry(
    List<WeightEntry> entries, {
    DateTime? now,
  }) {
    if (entries.isEmpty) return null;
    final currentDate = now ?? DateTime.now();
    final todayEntries = entries.where(
      (entry) =>
          entry.dateTime.year == currentDate.year &&
          entry.dateTime.month == currentDate.month &&
          entry.dateTime.day == currentDate.day,
    );
    final candidates = todayEntries.isNotEmpty ? todayEntries : entries;
    return candidates.reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b);
  }
}
