import 'package:flutter/material.dart';
import 'package:balance/features/statistics/presentation/widgets/components/bmi_delta_chip.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational header for the BMI card displaying the section title, delta trend chip, and legend trigger.
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
          Icon(Icons.monitor_weight_outlined, size: 24, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            l10n.bmi,
            style: textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Semantics(
            button: true,
            label: l10n.bmiLegendTitle,
            child: InkWell(
              onTap: onLegendTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 24,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.bmi,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        BmiDeltaChip(entries: entries, heightCm: heightCm!),
      ],
    );
  }
}
