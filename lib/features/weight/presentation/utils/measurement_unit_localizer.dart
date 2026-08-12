import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';

/// An extension providing localized labels for [MeasurementUnit].
extension MeasurementUnitX on MeasurementUnit {
  /// A human-readable label in the given locale.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      MeasurementUnit.metric => l10n.metricUnit,
      MeasurementUnit.imperial => l10n.imperialUnit,
    };
  }
}
