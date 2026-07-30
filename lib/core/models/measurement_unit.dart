import 'package:pure_weight/l10n/app_localizations.dart';

/// The unit system used for weight display.
enum MeasurementUnit {
  /// Kilograms and centimeters.
  metric,

  /// Pounds and feet/inches.
  imperial,
}

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
