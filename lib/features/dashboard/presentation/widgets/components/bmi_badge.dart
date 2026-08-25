import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A tappable presentational badge displaying BMI value, category, and status color.
class BmiBadge extends StatelessWidget {
  /// The computed BMI value.
  final double bmi;

  /// The category corresponding to [bmi].
  final BmiCategory? category;

  /// An optional callback invoked when the badge is tapped.
  final VoidCallback? onTap;

  const BmiBadge({super.key, required this.bmi, this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryColor = category != null
        ? category!.chipContentColor(isDark: isDark)
        : colorScheme.primary;
    final categoryBackground = category != null
        ? category!.chipBackgroundColor()
        : colorScheme.primary.withValues(alpha: 0.15);

    final categoryLabel = category?.localizedName(l10n) ?? '';

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(bmi.toStringAsFixed(1), categoryLabel),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: categoryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: categoryColor.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category == BmiCategory.normal
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        size: 13,
                        color: categoryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        categoryLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  l10n.bmiValueLabel(bmi.toStringAsFixed(1)),
                  style: textTheme.labelLarge?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
