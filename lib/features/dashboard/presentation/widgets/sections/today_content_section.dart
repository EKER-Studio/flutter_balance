import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/inline_error_banner.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/daily_tip_card.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/health_summary_card.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/weight_trend_chart_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/time_period.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';

/// The responsive content section composing summary, chart, tips, and error banner.
class TodayContentSection extends StatelessWidget {
  /// The latest entry representing the most recent measurement.
  final WeightEntry latestEntry;

  /// The entries to plot in the trend chart, filtered by [timePeriod].
  final List<WeightEntry> filteredEntries;

  /// The active chart time period.
  final TimePeriod timePeriod;

  /// An optional error type to show an inline error banner.
  final WeightErrorType? errorType;

  /// The user's active measurement unit.
  final MeasurementUnit measurementUnit;

  /// A callback fired when the chart time period is updated.
  final ValueChanged<TimePeriod> onPeriodChanged;

  /// An optional callback to retry data subscription.
  final VoidCallback? onRetry;

  /// The total number of entries recorded today.
  final int todayEntriesCount;

  const TodayContentSection({
    super.key,
    required this.latestEntry,
    required this.filteredEntries,
    required this.timePeriod,
    this.errorType,
    required this.measurementUnit,
    required this.onPeriodChanged,
    this.onRetry,
    this.todayEntriesCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600 || isLandscape;

        final Widget cardStack;
        if (isWide) {
          cardStack = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorType != null) ...[
                      InlineErrorBanner(
                        errorType: errorType!,
                        onRetry: onRetry,
                      ),
                      const SizedBox(height: 16),
                    ],
                    HealthSummaryCard(
                      latestWeightKg: latestEntry.weightKg,
                      lastUpdated: latestEntry.dateTime,
                      todayEntriesCount: todayEntriesCount,
                    ),
                    const SizedBox(height: 16),
                    const DailyTipCard(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WeightTrendChartCard(
                      entries: filteredEntries,
                      period: timePeriod,
                      measurementUnit: measurementUnit,
                      onPeriodChanged: onPeriodChanged,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        } else {
          cardStack = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (errorType != null) ...[
                InlineErrorBanner(errorType: errorType!, onRetry: onRetry),
                const SizedBox(height: 16),
              ],
              HealthSummaryCard(
                latestWeightKg: latestEntry.weightKg,
                lastUpdated: latestEntry.dateTime,
                todayEntriesCount: todayEntriesCount,
              ),
              const SizedBox(height: 16),
              WeightTrendChartCard(
                entries: filteredEntries,
                period: timePeriod,
                measurementUnit: measurementUnit,
                onPeriodChanged: onPeriodChanged,
              ),
              const SizedBox(height: 16),
              const DailyTipCard(),
              const SizedBox(height: 120),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 1200 : 600),
            child: cardStack,
          ),
        );
      },
    );
  }
}
