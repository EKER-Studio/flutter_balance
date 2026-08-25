import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_item.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A dialog that explains the WHO BMI categories, their colors, and healthy weight range.
class BmiLegendDialog extends StatelessWidget {
  const BmiLegendDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    AppSettingsState? settingsState;
    try {
      settingsState = context.read<AppSettingsBloc>().state;
    } catch (_) {
      settingsState = null;
    }

    final heightCm = settingsState?.height;
    final unit = settingsState?.measurementUnit ?? MeasurementUnit.metric;
    final isImperial = unit == MeasurementUnit.imperial;
    final unitLabel = isImperial ? 'lb' : 'kg';

    Widget? healthyWeightWidget;
    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      final minWeightKg = 18.5 * heightM * heightM;
      final maxWeightKg = 24.9 * heightM * heightM;

      final displayMin = isImperial ? kgToLbs(minWeightKg) : minWeightKg;
      final displayMax = isImperial ? kgToLbs(maxWeightKg) : maxWeightKg;

      final greenColor = isDark ? Colors.green.shade400 : Colors.green.shade700;

      healthyWeightWidget = MergeSemantics(
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.healthyWeightRange,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.healthyWeightRangeValue(
                  displayMin.toStringAsFixed(1),
                  displayMax.toStringAsFixed(1),
                  unitLabel,
                ),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: greenColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            const SizedBox(height: 2),
            BmiLegendItem(
              category: BmiCategory.normal,
              range: '18.5 – 24.9',
              isDark: isDark,
            ),
            const SizedBox(height: 2),
            BmiLegendItem(
              category: BmiCategory.overweight,
              range: '25.0 – 29.9',
              isDark: isDark,
            ),
            const SizedBox(height: 2),
            BmiLegendItem(
              category: BmiCategory.obeseClass1,
              range: '30.0 – 34.9',
              isDark: isDark,
            ),
            const SizedBox(height: 2),
            BmiLegendItem(
              category: BmiCategory.obeseClass2,
              range: '35.0 – 39.9',
              isDark: isDark,
            ),
            const SizedBox(height: 2),
            BmiLegendItem(
              category: BmiCategory.obeseClass3,
              range: '≥ 40.0',
              isDark: isDark,
            ),
            ?healthyWeightWidget,
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
