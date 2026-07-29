import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';

/// A compact health summary card showing BMI and goal progress.
class HealthSummaryCard extends StatelessWidget {
  /// The latest recorded weight in kilograms.
  final double latestWeightKg;

  /// Creates a [HealthSummaryCard] with the latest known weight.
  const HealthSummaryCard({super.key, required this.latestWeightKg});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        final heightCm = state.height;
        final targetWeight = state.targetWeight;
        final weightUnit = state.measurementUnit;
        final localization = AppLocalizations.of(context);
        final bmi = _calculateBmi(latestWeightKg, heightCm);
        final category = bmi.isFinite ? _bmiCategory(bmi) : null;
        final badgeColor = category != null
            ? _badgeColorForCategory(category)
            : Colors.blue;
        final goalText = _goalText(
          targetWeight,
          latestWeightKg,
          weightUnit,
          localization,
        );
        final goalSubtitle = _goalSubtitle(
          targetWeight,
          latestWeightKg,
          weightUnit,
          localization,
        );

        return Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: MergeSemantics(
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
                          localization.bmi,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                                category != null
                                    ? _interpretBmi(category, localization)
                                    : '',
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
                          localization.bmiSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                          localization.weightGoal,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          goalText,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          goalSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0) {
      return double.nan;
    }

    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }

  BmiCategory _bmiCategory(double bmi) {
    final state = AppSettingsState();
    return state.getBmiCategory(bmi);
  }

  Color _badgeColorForCategory(BmiCategory category) {
    return switch (category) {
      BmiCategory.underweight => Colors.blue,
      BmiCategory.normal => Colors.green,
      BmiCategory.overweight => Colors.orange,
      BmiCategory.obese => Colors.red,
    };
  }

  String _interpretBmi(BmiCategory category, AppLocalizations l10n) {
    return switch (category) {
      BmiCategory.underweight => l10n.bmiCategoryUnderweight,
      BmiCategory.normal => l10n.bmiCategoryNormal,
      BmiCategory.overweight => l10n.bmiCategoryOverweight,
      BmiCategory.obese => l10n.bmiCategoryObese,
    };
  }

  String _goalText(
    double? targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
    AppLocalizations l10n,
  ) {
    if (targetWeight == null) {
      return l10n.goalNotSet;
    }

    if (currentWeightKg <= targetWeight) {
      return l10n.goalAchieved;
    }

    final difference = currentWeightKg - targetWeight;
    final displayed = unit == MeasurementUnit.imperial
        ? kgToLbs(difference)
        : difference;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lb' : 'kg';

    return '${displayed.toStringAsFixed(1)} $unitLabel ${l10n.toTarget}';
  }

  String _goalSubtitle(
    double? targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
    AppLocalizations l10n,
  ) {
    if (targetWeight == null) {
      return l10n.setGoalMotivation;
    }

    final difference = currentWeightKg - targetWeight;
    if (difference <= 0.05 && difference >= -0.05) {
      return l10n.rightOnTarget;
    }

    final displayed = unit == MeasurementUnit.imperial
        ? kgToLbs(targetWeight)
        : targetWeight;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lbs' : 'kg';
    return '${l10n.targetLabel} ${displayed.toStringAsFixed(1)} $unitLabel';
  }
}
