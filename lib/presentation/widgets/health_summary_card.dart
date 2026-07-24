import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

/// A compact summary card for BMI and target weight progress.
class HealthSummaryCard extends StatelessWidget {
  /// The latest weight measurement in kilograms.
  final double latestWeightKg;

  /// Creates a [HealthSummaryCard].
  const HealthSummaryCard({super.key, required this.latestWeightKg});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppSettingsBloc>().state;
    final bmi = state.calculateBmi(latestWeightKg);
    final category = state.getBmiCategory(bmi);
    final l10n = AppLocalizations.of(context)!;
    final badgeColor = _badgeColorForCategory(category);
    final targetWeight = state.targetWeight;
    final unit = state.measurementUnit;

    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BMI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        bmi.isFinite ? bmi.toStringAsFixed(1) : '—',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _bmiCategoryLabel(category, l10n),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bmiDescription(category, l10n),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Goal',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _goalText(targetWeight, latestWeightKg, unit),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _goalSubtitle(targetWeight, latestWeightKg, unit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalText(
    double? targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
  ) {
    if (targetWeight == null) {
      return 'Goal not set';
    }

    final difference = currentWeightKg - targetWeight;
    if (difference <= 0.05 && difference >= -0.05) {
      return 'Goal achieved! 🎉';
    }

    final absDifference = difference.abs();
    final displayed = unit == MeasurementUnit.imperial
        ? kgToLbs(absDifference)
        : absDifference;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lb' : 'kg';
    final direction = difference > 0 ? 'to target' : 'to target';
    return '${displayed.toStringAsFixed(1)} $unitLabel $direction';
  }

  String _goalSubtitle(
    double? targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
  ) {
    if (targetWeight == null) {
      return 'Set a goal to stay motivated';
    }

    final difference = currentWeightKg - targetWeight;
    if (difference <= 0.05 && difference >= -0.05) {
      return 'You are right on target';
    }

    final displayed = unit == MeasurementUnit.imperial
        ? kgToLbs(targetWeight)
        : targetWeight;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lbs' : 'kg';
    return 'Target: ${displayed.toStringAsFixed(1)} $unitLabel';
  }

  Color _badgeColorForCategory(BmiCategory category) {
    return switch (category) {
      BmiCategory.underweight => Colors.blue,
      BmiCategory.normal => Colors.green,
      BmiCategory.overweight => Colors.orange,
      BmiCategory.obese => Colors.red,
    };
  }

  String _bmiCategoryLabel(BmiCategory category, AppLocalizations l10n) {
    return switch (category) {
      BmiCategory.underweight => l10n.bmiCategoryUnderweight,
      BmiCategory.normal => l10n.bmiCategoryNormal,
      BmiCategory.overweight => l10n.bmiCategoryOverweight,
      BmiCategory.obese => l10n.bmiCategoryObese,
    };
  }

  String _bmiDescription(BmiCategory category, AppLocalizations l10n) {
    return switch (category) {
      BmiCategory.underweight => l10n.bmiCategoryDescriptionUnderweight,
      BmiCategory.normal => l10n.bmiCategoryDescriptionNormal,
      BmiCategory.overweight => l10n.bmiCategoryDescriptionOverweight,
      BmiCategory.obese => l10n.bmiCategoryDescriptionObese,
    };
  }
}
