import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/statistics/domain/entities/period_comparison.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A card widget presenting a comparative analysis between the current and previous months.
class PeriodComparisonCard extends StatelessWidget {
  /// The comparison calculation result.
  final PeriodComparisonResult comparison;

  /// The active measurement unit.
  final MeasurementUnit unit;

  const PeriodComparisonCard({
    super.key,
    required this.comparison,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final unitLabel = unitLabelFor(unit);

    return Semantics(
      container: true,
      label: '${l10n.periodComparison}: ${l10n.thisMonthVsLast}',
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppAnalytics.logStatisticsPeriodComparisonCardTapped();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 24,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.periodComparison,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${comparison.currentPeriod.label} vs ${comparison.previousPeriod.label}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!comparison.hasComparisonData)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.comparisonNotEnoughData,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildComparisonRow(
                    context: context,
                    icon: Icons.trending_down_outlined,
                    label: l10n.netChange,
                    currentVal: _formatWeightChange(
                      comparison.currentPeriod.netChange,
                      unit,
                      unitLabel,
                    ),
                    previousVal: _formatWeightChange(
                      comparison.previousPeriod.netChange,
                      unit,
                      unitLabel,
                    ),
                    delta: _formatWeightChange(
                      comparison.deltaNetChange,
                      unit,
                      unitLabel,
                      prefixDelta: true,
                    ),
                    isPositiveImprovement:
                        comparison.deltaNetChange != null &&
                        comparison.deltaNetChange! < 0,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildComparisonRow(
                    context: context,
                    icon: Icons.monitor_weight_outlined,
                    label: l10n.averageWeight,
                    currentVal: _formatWeight(
                      comparison.currentPeriod.averageWeight,
                      unit,
                      unitLabel,
                    ),
                    previousVal: _formatWeight(
                      comparison.previousPeriod.averageWeight,
                      unit,
                      unitLabel,
                    ),
                    delta: _formatWeightChange(
                      comparison.deltaAverage,
                      unit,
                      unitLabel,
                      prefixDelta: true,
                    ),
                    isPositiveImprovement:
                        comparison.deltaAverage != null &&
                        comparison.deltaAverage! < 0,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildComparisonRow(
                    context: context,
                    icon: Icons.format_list_numbered_outlined,
                    label: l10n.totalMeasurements,
                    currentVal: l10n.measurementsCount(
                      comparison.currentPeriod.entryCount,
                    ),
                    previousVal: l10n.measurementsCount(
                      comparison.previousPeriod.entryCount,
                    ),
                    delta:
                        '${comparison.deltaEntryCount >= 0 ? "+" : ""}${comparison.deltaEntryCount}',
                    isPositiveImprovement: comparison.deltaEntryCount >= 0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String currentVal,
    required String previousVal,
    required String delta,
    required bool isPositiveImprovement,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$currentVal (vs $previousVal)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPositiveImprovement
                ? cs.primaryContainer.withValues(alpha: 0.7)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            delta,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPositiveImprovement
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatWeight(
    double? weightKg,
    MeasurementUnit unit,
    String unitLabel,
  ) {
    if (weightKg == null) return '-';
    final display = unit == MeasurementUnit.imperial
        ? kgToLbs(weightKg)
        : weightKg;
    return '${display.toStringAsFixed(1)} $unitLabel';
  }

  String _formatWeightChange(
    double? changeKg,
    MeasurementUnit unit,
    String unitLabel, {
    bool prefixDelta = false,
  }) {
    if (changeKg == null) return '-';
    final display = unit == MeasurementUnit.imperial
        ? kgToLbs(changeKg)
        : changeKg;
    final prefix = display > 0 ? '+' : '';
    final deltaPrefix = prefixDelta ? '\u0394 ' : '';
    return '$deltaPrefix$prefix${display.toStringAsFixed(1)} $unitLabel';
  }
}
