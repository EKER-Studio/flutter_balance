import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_item.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog that explains the BMI categories and their corresponding colors.
class BmiLegendDialog extends StatelessWidget {
  const BmiLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(l10n.bmiLegendTitle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BmiLegendItem(
              category: BmiCategory.underweight,
              range: '< 18.5',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            BmiLegendItem(
              category: BmiCategory.normal,
              range: '18.5 – 24.9',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            BmiLegendItem(
              category: BmiCategory.overweight,
              range: '25.0 – 29.9',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            BmiLegendItem(
              category: BmiCategory.obese,
              range: '≥ 30.0',
              isDark: isDark,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppAnalytics.logDialogBmiLegendClosed();
            Navigator.of(context).pop();
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
