import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/utils/weight_entry_formatting.dart';

void main() {
  final entry = WeightEntry(weightKg: 70.0, dateTime: DateTime(2026, 1, 1));

  group('formattedWeight', () {
    test('formats weight with metric unit as kg', () {
      expect(entry.formattedWeight(MeasurementUnit.metric), '70.0 kg');
    });

    test('formats weight with imperial unit as lbs', () {
      expect(entry.formattedWeight(MeasurementUnit.imperial), '154.3 lbs');
    });

    test('rounds metric weight to one decimal place', () {
      WeightEntry roundedEntry = WeightEntry(
        weightKg: 70.45,
        dateTime: DateTime(2026),
      );
      expect(roundedEntry.formattedWeight(MeasurementUnit.metric), '70.5 kg');
    });

    test('rounds imperial weight to one decimal place', () {
      WeightEntry roundedEntry = WeightEntry(
        weightKg: 70.45,
        dateTime: DateTime(2026),
      );
      expect(
        roundedEntry.formattedWeight(MeasurementUnit.imperial),
        '155.3 lbs',
      );
    });

    test('formats minimum valid weight', () {
      final minEntry = WeightEntry(
        weightKg: WeightEntry.minWeightKg,
        dateTime: DateTime(2026),
      );
      expect(minEntry.formattedWeight(MeasurementUnit.metric), '20.0 kg');
    });

    test('formats maximum valid weight in imperial', () {
      final maxEntry = WeightEntry(
        weightKg: WeightEntry.maxWeightKg,
        dateTime: DateTime(2026),
      );
      expect(maxEntry.formattedWeight(MeasurementUnit.imperial), '661.4 lbs');
    });
  });
}
