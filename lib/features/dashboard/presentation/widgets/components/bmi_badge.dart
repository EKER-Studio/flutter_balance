import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
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

  /// Creates a [BmiBadge] widget.
  const BmiBadge({
    super.key,
    required this.bmi,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = category != null
        ? category!.chipBackgroundColor()
        : colorScheme.primary.withValues(alpha: 0.1);

    final borderColor = category != null
        ? category!.chipContentColor(isDark: isDark).withValues(alpha: 0.3)
        : colorScheme.primary.withValues(alpha: 0.2);

    final contentColor = category != null
        ? category!.chipContentColor(isDark: isDark)
        : colorScheme.primary;

    final categoryLabel = category?.localizedName(l10n) ?? '';

    return Semantics(
      button: true,
      label: l10n.bmiCategorySemantics(bmi.toStringAsFixed(1), categoryLabel),
      excludeSemantics: true,
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            ? Icons.check_circle
                            : Icons.info,
                        size: 14,
                        color: contentColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          category!.localizedName(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.bmiValueShortLabel(bmi.toStringAsFixed(1)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w700,
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
