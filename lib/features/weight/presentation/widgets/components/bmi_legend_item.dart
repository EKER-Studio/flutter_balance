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
    final label = category.localizedName(l10n);
    final bgColor = category.chipBackgroundColor();
    final textColor = category.chipContentColor(isDark: isDark);

    final decoration = isCurrent
        ? BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.65)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withValues(alpha: 0.5),
              width: 1.0,
            ),
          )
        : null;

    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    children: [
                      if (isCurrent) ...[
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              l10n.yourResult,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: textColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                range,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isCurrent
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
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
