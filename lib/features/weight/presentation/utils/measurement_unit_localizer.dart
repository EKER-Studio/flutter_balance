import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Extension providing localized labels for [MeasurementUnit].
extension MeasurementUnitX on MeasurementUnit {
  /// Human-readable label in the given locale.
  String localizedName(AppLocalizations l10n) {
    return switch (this) {
      MeasurementUnit.metric => l10n.metricUnit,
      MeasurementUnit.imperial => l10n.imperialUnit,
    };
  }
}
