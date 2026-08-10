import 'package:flutter/material.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog that explains the BMI categories and their corresponding colors.
class BmiLegendDialog extends StatelessWidget {
  /// Creates a [BmiLegendDialog] explaining the BMI category ranges and colors.
  const BmiLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          ExcludeSemantics(child: Icon(Icons.info_outline, color: cs.primary)),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.bmiLegendTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLegendItem(
              context: context,
              category: BmiCategory.underweight,
              range: '< 18.5',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              category: BmiCategory.normal,
              range: '18.5 – 24.9',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              category: BmiCategory.overweight,
              range: '25.0 – 29.9',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              category: BmiCategory.obese,
              range: '≥ 30.0',
              isDark: isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }

  /// Builds one legend row: a colored range swatch, the category label,
  /// and the numeric BMI [range], shaded for light or dark mode.
  Widget _buildLegendItem({
    required BuildContext context,
    required BmiCategory category,
    required String range,
    required bool isDark,
  }) {
    final label = category.localizedName(AppLocalizations.of(context));
    final bgColor = category.chipBackgroundColor();
    final textColor = category.chipContentColor(isDark: isDark);

    return Row(
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
    );
  }
}
