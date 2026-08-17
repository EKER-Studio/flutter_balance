/// Pure utility functions for converting and formatting metric and imperial units.


import 'package:balance/core/models/measurement_unit.dart';

/// Converts a body weight from kilograms to pounds (lbs).
///
/// Formula: `lbs = kg * 2.20462`.
///
/// @param kg Weight in kilograms.
/// Returns the weight in pounds as a double.
double kgToLbs(double kg) => kg * 2.20462;

/// Converts a body weight from pounds (lbs) to kilograms.
///
/// Formula: `kg = lbs / 2.20462`.
///
/// @param lbs Weight in pounds.
/// Returns the weight in kilograms as a double.
double lbsToKg(double lbs) => lbs / 2.20462;

/// Converts a height in centimeters into whole feet and remaining inches.
///
/// Formula: `totalInches = cm / 2.54`, `feet = truncate(totalInches / 12)`,
/// `remainingInches = totalInches - feet * 12`, so `remainingInches` is in
/// the half-open range `[0, 12)` and negative inputs truncate toward zero.
///
/// @param cm Height in centimeters.
///// Returns the pair `[feet, remainingInches]`.
List<double> cmToFeetInches(double cm) {
  final totalInches = cm / 2.54;
  final feet = (totalInches / 12).truncateToDouble();
  final remainingInches = totalInches - (feet * 12);
  return [feet, remainingInches];
}

/// Formats a body weight stored in kilograms for user display according to [unit].
///
/// Formats as `X.X kg` for metric or `X.X lbs` for imperial, always with one
/// decimal place.
///
/// @param weightKg Weight in kilograms.
/// @param unit Target display unit system.
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

/// The label for BMI values, which are always expressed in kg/m².
const String bmiUnitLabel = 'kg/m²';

/// Formats a height stored in centimeters for user display according to [unit].
///
/// Formats as `X cm` for metric (no decimals) or `F'I"` for imperial, where
/// the remaining inches are rounded to the nearest whole number.
///
/// @param heightCm Height in centimeters.
/// @param unit Target display unit system.
String formatHeight(double heightCm, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final [feet, inches] = cmToFeetInches(heightCm);
    final roundedInches = inches.roundToDouble();
    return '${feet.toInt()}\'${roundedInches.toStringAsFixed(0)}"';
  }
  return '${heightCm.toStringAsFixed(0)} cm';
}
