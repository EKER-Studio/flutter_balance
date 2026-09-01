import 'package:flutter/material.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A compact statistics card displaying the user's BMI score, WHO category,
/// visual 4-zone spectrum gauge, and healthy weight range for their height.
class BmiStatusCard extends StatelessWidget {
  /// The recorded weight entries.
  final List<WeightEntry> entries;

  /// The user's height in centimeters, if configured.
  final double? heightCm;

  /// The active measurement unit.
  final MeasurementUnit unit;

  const BmiStatusCard({
    super.key,
    required this.entries,
    required this.heightCm,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final unitLabel = unitLabelFor(unit);

    final hasHeight = heightCm != null && heightCm! > 0;
    final hasEntries = entries.isNotEmpty;

    final latestEntry = hasEntries
        ? (entries.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime)))
              .first
        : null;

    final latestWeightKg = latestEntry?.weightKg;

    double? bmi;
    BmiCategory? category;
    double? minHealthyKg;
    double? maxHealthyKg;
    double? distanceToNormalKg;
    bool isAboveNormal = false;

    if (hasHeight && latestWeightKg != null) {
      final heightM = heightCm! / 100.0;
      bmi = latestWeightKg / (heightM * heightM);
      category = BmiCategory.fromBmi(bmi);
      minHealthyKg = 18.5 * heightM * heightM;
      maxHealthyKg = 24.9 * heightM * heightM;

      if (latestWeightKg > maxHealthyKg) {
        distanceToNormalKg = latestWeightKg - maxHealthyKg;
        isAboveNormal = true;
      } else if (latestWeightKg < minHealthyKg) {
        distanceToNormalKg = minHealthyKg - latestWeightKg;
      }
    }

    return Semantics(
      container: true,
      label: bmi != null && category != null
          ? '${l10n.bmi}: ${bmi.toStringAsFixed(1)}, ${category.localizedName(l10n)}'
          : l10n.bmi,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showLegendDialog(context, latestWeightKg),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed_outlined, size: 24, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.bmi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: l10n.bmiLegendTitle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _showLegendDialog(context, latestWeightKg),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!hasHeight)
                  _buildInfoMessage(
                    context,
                    icon: Icons.straighten_outlined,
                    message: l10n.setHeightForBmi,
                  )
                else if (!hasEntries || bmi == null || category == null)
                  _buildInfoMessage(
                    context,
                    icon: Icons.monitor_weight_outlined,
                    message: l10n.noDataToAnalyzeSubtitle,
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        bmi.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.chipBackgroundColor(),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: category
                                .chipContentColor(isDark: isDark)
                                .withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category == BmiCategory.normal
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 13,
                              color: category.chipContentColor(isDark: isDark),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category.localizedName(l10n),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: category.chipContentColor(
                                      isDark: isDark,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSpectrumBar(context, bmi: bmi),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.healthyWeightForHeight(
                                  '${_formatWeight(minHealthyKg!, unit, unitLabel)} – ${_formatWeight(maxHealthyKg!, unit, unitLabel)}',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (distanceToNormalKg != null &&
                            distanceToNormalKg > 0.05) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isAboveNormal
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                size: 16,
                                color: cs.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.distanceToNormalBmi(
                                    _formatWeight(
                                      distanceToNormalKg,
                                      unit,
                                      unitLabel,
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ] else if (category == BmiCategory.normal) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.inNormalBmiRange,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpectrumBar(BuildContext context, {required double bmi}) {
    final cs = Theme.of(context).colorScheme;

    // Proportional fraction across BMI 15.0 to 35.0 spectrum
    final normalized = ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.02, 0.98);

    return Column(
      children: [
        // Arrow indicator pointing down to active zone
        LayoutBuilder(
          builder: (context, constraints) {
            final position = constraints.maxWidth * normalized;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(width: constraints.maxWidth, height: 10),
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: (position - 6).clamp(0.0, constraints.maxWidth - 12),
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: cs.onSurface,
                  ),
                ),
              ],
            );
          },
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: 35, // 15.0 to 18.5
                child: Container(
                  height: 8,
                  color: Colors.blue.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 64, // 18.5 to 24.9
                child: Container(
                  height: 8,
                  color: Colors.green.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 50, // 25.0 to 29.9
                child: Container(
                  height: 8,
                  color: Colors.orange.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 51, // 30.0 to 35.0+
                child: Container(
                  height: 8,
                  color: Colors.red.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '< 18.5',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '18.5 – 24.9',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '25 – 29.9',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '≥ 30',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegendDialog(BuildContext context, double? latestWeightKg) {
    AppAnalytics.logStatisticsBmiLegendTapped();
    AppAnalytics.logDialogBmiLegendOpened();
    showDialog<void>(
      context: context,
      builder: (_) =>
          BmiLegendDialog(latestWeightKg: latestWeightKg, heightCm: heightCm),
    );
  }

  String _formatWeight(
    double weightKg,
    MeasurementUnit unit,
    String unitLabel,
  ) {
    final display = unit == MeasurementUnit.imperial
        ? kgToLbs(weightKg)
        : weightKg;
    return '${display.toStringAsFixed(1)} $unitLabel';
  }
}
