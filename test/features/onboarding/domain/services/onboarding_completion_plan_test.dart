import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/onboarding/domain/services/onboarding_completion_plan.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  group('OnboardingCompletionPlan.fromDraft', () {
    final now = DateTime(2026, 9, 2, 12, 0);

    WeightEntry makeEntry(DateTime dt, double weight, {int id = 0}) {
      return WeightEntry(id: id, weightKg: weight, dateTime: dt);
    }

    test('empty import yields an empty entriesToImport', () {
      final plan = OnboardingCompletionPlan.fromDraft(
        importedEntries: const [],
        healthSyncRequested: true,
        biometricLockRequested: true,
        healthSyncEnabled: false,
        biometricLockEnabled: false,
        now: now,
      );

      expect(plan.entriesToImport, isEmpty);
      expect(plan.enableHealthSync, isTrue);
      expect(plan.enableBiometricLock, isTrue);
    });

    test('single entry is treated as the latest and not re-imported', () {
      final entry = makeEntry(DateTime(2026, 9, 2, 8, 0), 70.0, id: 1);

      final plan = OnboardingCompletionPlan.fromDraft(
        importedEntries: [entry],
        healthSyncRequested: false,
        biometricLockRequested: false,
        healthSyncEnabled: false,
        biometricLockEnabled: false,
        now: now,
      );

      expect(plan.entriesToImport, isEmpty);
    });

    test('excludes the latest entry and keeps the rest', () {
      final earlier = makeEntry(DateTime(2026, 8, 1, 8, 0), 72.0, id: 1);
      final latest = makeEntry(DateTime(2026, 9, 2, 8, 0), 70.0, id: 2);

      final plan = OnboardingCompletionPlan.fromDraft(
        importedEntries: [earlier, latest],
        healthSyncRequested: false,
        biometricLockRequested: false,
        healthSyncEnabled: false,
        biometricLockEnabled: false,
        now: now,
      );

      expect(plan.entriesToImport, [earlier]);
      expect(plan.entriesToImport, isNot(contains(latest)));
    });

    test('entriesToImport is unmodifiable', () {
      final earlier = makeEntry(DateTime(2026, 8, 1, 8, 0), 72.0, id: 1);
      final latest = makeEntry(DateTime(2026, 9, 2, 8, 0), 70.0, id: 2);

      final plan = OnboardingCompletionPlan.fromDraft(
        importedEntries: [earlier, latest],
        healthSyncRequested: false,
        biometricLockRequested: false,
        healthSyncEnabled: false,
        biometricLockEnabled: false,
        now: now,
      );

      expect(
        () => plan.entriesToImport.add(latest),
        throwsA(isA<UnsupportedError>()),
      );
    });

    group('enableHealthSync', () {
      test('is true only when requested and not already enabled', () {
        for (final (requested, enabled, expected) in [
          (true, false, true),
          (true, true, false),
          (false, false, false),
          (false, true, false),
        ]) {
          final plan = OnboardingCompletionPlan.fromDraft(
            importedEntries: const [],
            healthSyncRequested: requested,
            biometricLockRequested: false,
            healthSyncEnabled: enabled,
            biometricLockEnabled: false,
            now: now,
          );
          expect(
            plan.enableHealthSync,
            expected,
            reason: 'requested=$requested enabled=$enabled',
          );
        }
      });
    });

    group('enableBiometricLock', () {
      test('is true only when requested and not already enabled', () {
        for (final (requested, enabled, expected) in [
          (true, false, true),
          (true, true, false),
          (false, false, false),
          (false, true, false),
        ]) {
          final plan = OnboardingCompletionPlan.fromDraft(
            importedEntries: const [],
            healthSyncRequested: false,
            biometricLockRequested: requested,
            healthSyncEnabled: false,
            biometricLockEnabled: enabled,
            now: now,
          );
          expect(
            plan.enableBiometricLock,
            expected,
            reason: 'requested=$requested enabled=$enabled',
          );
        }
      });
    });
  });

  group('OnboardingCompletionPlan.latestImportedEntry', () {
    final now = DateTime(2026, 9, 2, 12, 0);

    WeightEntry makeEntry(DateTime dt, double weight, {int id = 0}) {
      return WeightEntry(id: id, weightKg: weight, dateTime: dt);
    }

    test('returns null for an empty list', () {
      expect(
        OnboardingCompletionPlan.latestImportedEntry(const [], now: now),
        isNull,
      );
    });

    test('prefers the latest entry from today over older entries', () {
      final yesterday = makeEntry(DateTime(2026, 9, 1, 9, 0), 71.0, id: 1);
      final todayEarly = makeEntry(DateTime(2026, 9, 2, 7, 0), 70.5, id: 2);
      final todayLate = makeEntry(DateTime(2026, 9, 2, 18, 0), 70.0, id: 3);

      final latest = OnboardingCompletionPlan.latestImportedEntry([
        yesterday,
        todayEarly,
        todayLate,
      ], now: now);

      expect(latest, todayLate);
    });

    test(
      'falls back to the latest historical entry when none are from today',
      () {
        final older = makeEntry(DateTime(2026, 8, 1, 9, 0), 72.0, id: 1);
        final recent = makeEntry(DateTime(2026, 8, 30, 9, 0), 71.0, id: 2);

        final latest = OnboardingCompletionPlan.latestImportedEntry([
          older,
          recent,
        ], now: now);

        expect(latest, recent);
      },
    );

    test('selects by dateTime, independent of list order', () {
      final a = makeEntry(DateTime(2026, 9, 2, 6, 0), 70.9, id: 1);
      final b = makeEntry(DateTime(2026, 9, 2, 20, 0), 70.1, id: 2);
      final c = makeEntry(DateTime(2026, 9, 2, 12, 0), 70.5, id: 3);

      final latest = OnboardingCompletionPlan.latestImportedEntry([
        a,
        c,
        b,
      ], now: now);

      expect(latest, b);
    });

    test('uses the supplied now for the "today" comparison', () {
      // Entry is "today" only relative to the supplied now, not the real clock.
      final entry = makeEntry(DateTime(2026, 1, 15, 8, 0), 70.0, id: 1);

      final latest = OnboardingCompletionPlan.latestImportedEntry([
        entry,
      ], now: DateTime(2026, 1, 15, 12, 0));

      expect(latest, entry);
    });
  });
}
