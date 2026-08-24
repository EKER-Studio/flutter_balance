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

  const BmiLegendItem({
    super.key,
    required this.category,
    required this.range,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = category.localizedName(AppLocalizations.of(context));
    final bgColor = category.chipBackgroundColor();
    final textColor = category.chipContentColor(isDark: isDark);

    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          AppAnalytics.logDialogBmiLegendCategoryTapped(category.name);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: textColor, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                range,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
