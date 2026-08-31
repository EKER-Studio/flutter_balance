import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational row widget displaying a colored category swatch, localized title, and numeric BMI range.
class BmiLegendItem extends StatelessWidget {
  final BmiCategory category;
  final String range;
  final bool isDark;
  final bool isCurrent;

  const BmiLegendItem({
    super.key,
    required this.category,
    required this.range,
    required this.isDark,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = category.localizedName(l10n);
    final bgColor = category.chipBackgroundColor();
    final textColor = category.chipContentColor(isDark: isDark);

    final decoration = isCurrent
        ? BoxDecoration(
            color: category.chipBackgroundColor().withValues(
              alpha: isDark ? 0.35 : 0.22,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textColor, width: 1.5),
          )
        : null;

    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          AppAnalytics.logDialogBmiLegendCategoryTapped(category.name);
        },
        child: Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: textColor, width: 2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: isCurrent
                      ? Center(
                          child: Icon(Icons.check, size: 12, color: textColor),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isCurrent ? textColor : colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: textColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.yourResult,
                              style: textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? colorScheme.surface
                                    : colorScheme.onPrimary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                range,
                style: textTheme.bodyMedium?.copyWith(
                  color: isCurrent ? textColor : colorScheme.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
