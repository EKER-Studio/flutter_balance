/// Summary metrics for a single calendar time period.
class PeriodSummary {
  /// The first recorded weight in the period, if any.
  final double? startWeight;

  /// The latest recorded weight in the period, if any.
  final double? endWeight;

  /// The net weight change in kg (`endWeight - startWeight`), or null if fewer than 2 entries.
  final double? netChange;

  /// The arithmetic mean weight across all measurements in the period.
  final double? averageWeight;

  /// The total number of measurements logged in the period.
  final int entryCount;

  /// The name or label of the period (e.g. "August", "July").
  final String label;

  const PeriodSummary({
    required this.startWeight,
    required this.endWeight,
    required this.netChange,
    required this.averageWeight,
    required this.entryCount,
    required this.label,
  });
}

/// The comparative result between two adjacent calendar time periods.
class PeriodComparisonResult {
  /// Metrics for the current active period (e.g. this month).
  final PeriodSummary currentPeriod;

  /// Metrics for the baseline comparison period (e.g. previous month).
  final PeriodSummary previousPeriod;

  /// The difference in net weight change between periods (`current.netChange - previous.netChange`).
  final double? deltaNetChange;

  /// The difference in average weight between periods (`current.averageWeight - previous.averageWeight`).
  final double? deltaAverage;

  /// The difference in measurement frequency (`current.entryCount - previous.entryCount`).
  final int deltaEntryCount;

  /// Whether sufficient data exists in both periods to draw meaningful comparisons.
  final bool hasComparisonData;

  const PeriodComparisonResult({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.deltaNetChange,
    required this.deltaAverage,
    required this.deltaEntryCount,
    required this.hasComparisonData,
  });
}
