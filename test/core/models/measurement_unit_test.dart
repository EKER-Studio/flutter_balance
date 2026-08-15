import 'package:balance/core/models/measurement_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasurementUnit', () {
    test('has exactly two values', () {
      expect(MeasurementUnit.values.length, 2);
    });

    test('values are metric and imperial', () {
      expect(MeasurementUnit.values, [
        MeasurementUnit.metric,
        MeasurementUnit.imperial,
      ]);
    });

    test('metric is not equal to imperial', () {
      expect(MeasurementUnit.metric, isNot(equals(MeasurementUnit.imperial)));
    });

    test('index of metric is 0', () {
      expect(MeasurementUnit.metric.index, 0);
    });

    test('index of imperial is 1', () {
      expect(MeasurementUnit.imperial.index, 1);
    });

    test('name of metric is "metric"', () {
      expect(MeasurementUnit.metric.name, 'metric');
    });

    test('name of imperial is "imperial"', () {
      expect(MeasurementUnit.imperial.name, 'imperial');
    });
  });
}
