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

    test('formats metric summary with target weight and weight loss', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 85.0, dateTime: DateTime(2026, 8, 1)),
        WeightEntry(id: 2, weightKg: 80.0, dateTime: DateTime(2026, 8, 20)),
      ];

      final summary = ProgressSummaryFormatter.format(
        entries: entries,
        targetWeight: 75.0,
        unit: MeasurementUnit.metric,
        l10n: l10n,
      );

      expect(summary, contains('Total Progress'));
      expect(summary, contains('85.0 kg'));
      expect(summary, contains('80.0 kg (-5.0 kg)'));
      expect(summary, contains('75.0 kg'));
      expect(summary, contains('5.0 kg'));
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
      );

      expect(summary, contains('lb'));
      expect(summary, contains('176.4 lb'));
      expect(summary, contains('172.0 lb'));
    });
  });
}
