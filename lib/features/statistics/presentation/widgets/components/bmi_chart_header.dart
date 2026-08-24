import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational header for the BMI card displaying the section title, category chip, and legend trigger.
class BmiChartHeader extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? heightCm;
  final VoidCallback onLegendTap;

  const BmiChartHeader({
    super.key,
    required this.entries,
    required this.heightCm,
    required this.onLegendTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (heightCm == null || heightCm! <= 0 || entries.isEmpty) {
      return Row(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            l10n.bmi,
            style: textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.help_outline,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            onPressed: onLegendTap,
            tooltip: l10n.bmiLegendTitle,
          ),
        ],
      );
    }

    final sorted = [...entries]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final hMeters = heightCm! / 100.0;
    final bmi = sorted.first.weightKg / (hMeters * hMeters);
    final category = BmiCategory.fromBmi(bmi);
    final categoryLabel = category.localizedName(l10n);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(bmi.toStringAsFixed(1), categoryLabel),
      excludeSemantics: true,
      child: InkWell(
        onTap: onLegendTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                l10n.bmi,
                style: textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: category.chipBackgroundColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: category.chipContentColor(isDark: isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        color: category.chipContentColor(isDark: isDark),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
