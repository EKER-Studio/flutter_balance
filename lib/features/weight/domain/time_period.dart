/// A domain enum and constants for time-based filtering of weight history.
library;

/// The selected time period for the chart filter.
enum TimePeriod {
  /// Last 7 days.
  week,

  /// Last 30 days.
  month,

  /// Last 365 days.
  year,

  /// All time.
  all,
}

/// An extension providing domain-level lookback durations for [TimePeriod].
extension TimePeriodX on TimePeriod {
  /// How far back this period looks from now.
  Duration get lookbackDuration => switch (this) {
    TimePeriod.week => const Duration(days: 7),
    TimePeriod.month => const Duration(days: 30),
    TimePeriod.year => const Duration(days: 365),
    TimePeriod.all => Duration.zero,
  };
}

/// The number of days used as the lookback window for monthly compliance.
const int monthlyComplianceDays = 30;
