import 'package:flutter/material.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// A dialog that explains the BMI categories and their corresponding colors.
class BmiLegendDialog extends StatelessWidget {
  const BmiLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: cs.primary),
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
              label: l10n.bmiCategoryUnderweight,
              range: '< 18.5',
              baseColor: Colors.blue,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              label: l10n.bmiCategoryNormal,
              range: '18.5 – 24.9',
              baseColor: Colors.green,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              label: l10n.bmiCategoryOverweight,
              range: '25.0 – 29.9',
              baseColor: Colors.orange,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              context: context,
              label: l10n.bmiCategoryObese,
              range: '≥ 30.0',
              baseColor: Colors.red,
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

  Widget _buildLegendItem({
    required BuildContext context,
    required String label,
    required String range,
    required MaterialColor baseColor,
    required bool isDark,
  }) {
    final bgColor = baseColor.withValues(alpha: 0.15);
    final textColor = isDark ? baseColor.shade300 : baseColor.shade800;

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: textColor, width: 2),
            borderRadius: BorderRadius.circular(4),
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
