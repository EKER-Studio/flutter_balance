import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';

void main() {
  group('MeasurementUnit', () {
    test('contains metric and imperial values', () {
      expect(MeasurementUnit.values.length, 2);
      expect(MeasurementUnit.metric.index, 0);
      expect(MeasurementUnit.imperial.index, 1);
    });
  });
}
