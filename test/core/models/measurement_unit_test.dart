import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';

void main() {
  group('MeasurementUnit', () {
    test('has metric and imperial values', () {
      final values = MeasurementUnit.values;
      expect(values, hasLength(2));
      expect(values, contains(MeasurementUnit.metric));
      expect(values, contains(MeasurementUnit.imperial));
    });

    test('metric index is 0', () {
      expect(MeasurementUnit.metric.index, 0);
    });

    test('imperial index is 1', () {
      expect(MeasurementUnit.imperial.index, 1);
    });
  });
}
