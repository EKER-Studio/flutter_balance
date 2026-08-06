import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/weight/presentation/utils/measurement_unit_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('MeasurementUnitX.localizedName', () {
    test('maps metric to the localized metric label', () {
      expect(MeasurementUnit.metric.localizedName(l10n), l10n.metricUnit);
    });

    test('maps imperial to the localized imperial label', () {
      expect(MeasurementUnit.imperial.localizedName(l10n), l10n.imperialUnit);
    });

    test('returns distinct labels for distinct units', () {
      final labels = MeasurementUnit.values
          .map((u) => u.localizedName(l10n))
          .toSet();
      expect(labels.length, MeasurementUnit.values.length);
    });
  });
}
