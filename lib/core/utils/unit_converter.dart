import 'package:balance/core/models/measurement_unit.dart';

/// Converts a body weight from kilograms to pounds.
///
/// Formula: `lbs = kg * 2.20462`.
double kgToLbs(double kg) => kg * 2.20462;

/// Converts a body weight from pounds to kilograms.
///
/// Formula: `kg = lbs / 2.20462`.
double lbsToKg(double lbs) => lbs / 2.20462;

/// Converts a height in centimeters into whole feet and remaining inches.
///
/// Returns `[feet, remainingInches]` where `remainingInches` is in `[0, 12)`.
/// Formula: `totalInches = cm / 2.54`, `feet = truncate(totalInches / 12)`,
/// `remainingInches = totalInches - feet * 12`.
List<double> cmToFeetInches(double cm) {
  final totalInches = cm / 2.54;
  final feet = (totalInches / 12).truncateToDouble();
  final remainingInches = totalInches - (feet * 12);
  return [feet, remainingInches];
}

/// Formats a body weight stored in kilograms for user display according to [unit].
///
/// Formats as `X.X kg` for metric or `X.X lbs` for imperial, always with one decimal place.
String formatWeight(double weightKg, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final lbs = kgToLbs(weightKg);
    return '${lbs.toStringAsFixed(1)} lbs';
  }
  return '${weightKg.toStringAsFixed(1)} kg';
}

/// Returns the plain unit suffix (`kg` or `lb`) for the given [unit].
String unitLabelFor(MeasurementUnit unit) {
  return unit == MeasurementUnit.imperial ? 'lb' : 'kg';
}

/// The unit label for BMI values, which are always expressed in kg/m².
const String bmiUnitLabel = 'kg/m²';

/// Formats a height stored in centimeters for user display according to [unit].
///
/// Formats as `X cm` for metric (no decimals) or `F'I"` for imperial,
/// where remaining inches are rounded to the nearest whole number.
String formatHeight(double heightCm, MeasurementUnit unit) {
  if (unit == MeasurementUnit.imperial) {
    final [feet, inches] = cmToFeetInches(heightCm);
    final roundedInches = inches.roundToDouble();
    return '${feet.toInt()}\'${roundedInches.toStringAsFixed(0)}"';
  }
  return '${heightCm.toStringAsFixed(0)} cm';
}

/// Formats a height value for editable input fields, preserving one decimal place.
///
/// Whole numbers render without decimals (`175.0` → `'175'`) so integer
/// input is unchanged, while fractional values keep one decimal
/// (`177.6` → `'177.6'`). Used for both metric (cm) and imperial (inches)
/// fields so a stored height round-trips through the UI without silent
/// rounding (e.g. `177.6` no longer reopens as `178`).
String formatHeightInput(double value) {
  final oneDecimal = value.toStringAsFixed(1);
  return oneDecimal.endsWith('.0')
      ? oneDecimal.substring(0, oneDecimal.length - 2)
      : oneDecimal;
}

/// Parses a user-typed decimal accepting both `.` and `,` as separators.
///
/// Trims surrounding whitespace and treats `,` as the decimal separator
/// (e.g. `'177,6'` → `177.6`), covering locales with either convention.
/// Returns `null` for blank or unparseable input.
double? tryParseLocalizedNumber(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// Converts imperial height fields into centimeters, or `null` when invalid.
///
/// Empty fields count as zero (inches-only input is accepted), while
/// unparseable or negative values reject the whole input. Range checking
/// against the allowed height bounds stays with the caller.
double? tryParseImperialHeightCm(String feetRaw, String inchesRaw) {
  final feet = feetRaw.trim().isEmpty ? 0.0 : tryParseLocalizedNumber(feetRaw);
  final inches = inchesRaw.trim().isEmpty
      ? 0.0
      : tryParseLocalizedNumber(inchesRaw);
  if (feet == null || inches == null || feet.isNaN || inches.isNaN) {
    return null;
  }
  if (feet < 0 || inches < 0) return null;
  return (feet * 12 + inches) * 2.54;
}

/// Classifies a height validation failure for analytics.
///
/// Returns only categorical values (`'empty'`, `'parse_error'`,
/// `'out_of_range'`) — never the raw input — keeping telemetry
/// privacy-compliant. Call with the parse result: when the parsed value is
/// non-null here, the failure necessarily means out-of-range.
String heightValidationErrorType({
  required bool isEmpty,
  required double? parsedValue,
}) {
  if (isEmpty) return 'empty';
  if (parsedValue == null) return 'parse_error';
  return 'out_of_range';
}
