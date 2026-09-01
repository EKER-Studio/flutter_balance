import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/presentation/utils/progress_summary_formatter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('ProgressSummaryFormatter', () {
    test('returns empty string when entries is empty', () {
      final summary = ProgressSummaryFormatter.format(
        entries: [],
        unit: MeasurementUnit.metric,
        l10n: l10n,
      );

      expect(summary, isEmpty);
    });

    test('formats comprehensive metric summary with all sections', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 91.0, dateTime: DateTime(2026, 5, 30)),
        WeightEntry(id: 2, weightKg: 87.0, dateTime: DateTime(2026, 7, 15)),
        WeightEntry(id: 3, weightKg: 85.6, dateTime: DateTime(2026, 9, 1)),
      ];

      final summary = ProgressSummaryFormatter.format(
        entries: entries,
        targetWeight: 86.0,
        heightCm: 177.0,
        paceWindowDays: 30,
        unit: MeasurementUnit.metric,
        l10n: l10n,
        now: DateTime(2026, 9, 1),
      );

      expect(summary, contains('Total Progress'));
      expect(summary, contains('Progress & Goal'));
      expect(summary, contains('Start: 91.0 kg'));
      expect(summary, contains('Current weight: 85.6 kg'));
      expect(summary, contains('Total change: -5.4 kg (-5.9%)'));
      expect(summary, contains('Target Weight: 86.0 kg (Goal achieved! 🎉)'));
      expect(summary, contains('BMI: 27.3 (Overweight)'));

      expect(summary, contains('Range & Average'));
      expect(summary, contains('Highest: 91.0 kg'));
      expect(summary, contains('Lowest: 85.6 kg'));
      expect(summary, contains('Average Weight: 87.9 kg'));
      expect(summary, contains('Total measurements: 3'));

      expect(summary, contains('Habits & Consistency'));
      expect(summary, contains('Current streak: 1 day'));
      expect(summary, contains('Achievements:'));
      expect(summary, contains('Balance — Simple, private weight tracker'));
    });

    test('formats imperial summary in lbs', () {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 80.0,
          dateTime: DateTime(2026, 8, 1),
        ), // ~176.4 lbs
        WeightEntry(
          id: 2,
          weightKg: 78.0,
          dateTime: DateTime(2026, 8, 20),
        ), // ~172.0 lbs
      ];

      final summary = ProgressSummaryFormatter.format(
        entries: entries,
        unit: MeasurementUnit.imperial,
        l10n: l10n,
        now: DateTime(2026, 8, 20),
      );

      expect(summary, contains('lb'));
      expect(summary, contains('176.4 lb'));
      expect(summary, contains('172.0 lb'));
      expect(summary, contains('-4.4 lb'));
    });
  });
}
