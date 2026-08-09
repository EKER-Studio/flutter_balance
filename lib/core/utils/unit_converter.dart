/// Pure utility functions for converting and formatting metric and imperial units.
library;

import 'package:balance/core/models/measurement_unit.dart';

/// Converts a body weight from kilograms to pounds (lbs).
///
/// Takes [kg] in kilograms.
/// Multiplies by constant factor 2.20462.
/// Returns the calculated weight in pounds as a double.
double kgToLbs(double kg) => kg * 2.20462;

/// Converts a body weight from pounds (lbs) to kilograms.
///
/// Takes [lbs] in pounds.
/// Divides by constant factor 2.20462.
/// Returns the calculated weight in kilograms as a double.
double lbsToKg(double lbs) => lbs / 2.20462;

/// Converts a height in centimeters into feet and remaining inches.
///
/// Takes [cm] in centimeters.
/// Returns a List of two doubles `[feet, remainingInches]`.
List<double> cmToFeetInches(double cm) {
  final totalInches = cm / 2.54;
  final feet = (totalInches / 12).floorToDouble();
  final remainingInches = totalInches - (feet * 12);
  return [feet, remainingInches];
}

/// Formats a body weight stored in kilograms for user display according to [unit].
///
/// Takes [weightKg] in kilograms and the target [MeasurementUnit] [unit].
/// Formats as `X.X kg` for metric or `X.X lbs` for imperial.
/// Returns a formatted string representation.
String formatWeight(double weightKg, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final lbs = kgToLbs(weightKg);
    return '${lbs.toStringAsFixed(1)} lbs';
  }
  return '${weightKg.toStringAsFixed(1)} kg';
}

/// Returns the plain unit suffix for the given [unit] (`kg` or `lb`).
String unitLabelFor(MeasurementUnit unit) {
  return unit == MeasurementUnit.imperial ? 'lb' : 'kg';
}

/// Label for BMI values, which are always expressed in kg/m².
const String bmiUnitLabel = 'kg/m²';

/// Formats a height stored in centimeters for user display according to [unit].
///
/// Takes [heightCm] in centimeters and the target [MeasurementUnit] [unit].
/// Formats as `X cm` for metric or `X'Y"` for imperial.
/// Returns a formatted string representation.
String formatHeight(double heightCm, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final [feet, inches] = cmToFeetInches(heightCm);
    final roundedInches = inches.roundToDouble();
    return '${feet.toInt()}\'${roundedInches.toStringAsFixed(0)}"';
  }
  return '${heightCm.toStringAsFixed(0)} cm';
}
