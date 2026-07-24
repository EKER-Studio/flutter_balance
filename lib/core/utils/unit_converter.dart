/// Pure utility functions for converting between metric and imperial units.
///
/// All conversions use fixed precision constants.
library;

import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

/// Converts kilograms to pounds.
double kgToLbs(double kg) => kg * 2.20462;

/// Converts pounds to kilograms.
double lbsToKg(double lbs) => lbs / 2.20462;

/// Parses a height in centimeters into feet and inches.
///
/// Returns a list of two doubles: `[feet, inches]`.
List<double> cmToFeetInches(double cm) {
  final totalInches = cm / 2.54;
  final feet = (totalInches / 12).floorToDouble();
  final remainingInches = totalInches - (feet * 12);
  return [feet, remainingInches];
}

/// Formats a weight value with the appropriate unit label.
String formatWeight(double weightKg, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final lbs = kgToLbs(weightKg);
    return '${lbs.toStringAsFixed(1)} lbs';
  }
  return '${weightKg.toStringAsFixed(1)} kg';
}

/// Formats a height value (stored in cm) with the appropriate unit label.
String formatHeight(double heightCm, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final [feet, inches] = cmToFeetInches(heightCm);
    final roundedInches = inches.roundToDouble();
    return '${feet.toInt()}\'${roundedInches.toStringAsFixed(0)}"';
  }
  return '${heightCm.toStringAsFixed(0)} cm';
}
