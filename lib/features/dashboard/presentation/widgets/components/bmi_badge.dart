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

    final categoryLabel = category?.localizedName(l10n) ?? '';

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(bmi.toStringAsFixed(1), categoryLabel),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.bmiValueLabel(bmi.toStringAsFixed(1)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (category != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: categoryColor, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
