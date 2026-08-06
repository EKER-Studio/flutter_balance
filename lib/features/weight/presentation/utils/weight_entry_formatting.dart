import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// Utility formatting extensions on [WeightEntry] for presentation conversion.
extension WeightEntryFormatting on WeightEntry {
  /// Formats [weightKg] into a display string based on the active [unit] measurement system.
  String formattedWeight(MeasurementUnit unit) => formatWeight(weightKg, unit);
}
