import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/measurement_unit.dart';

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
        final bmi = _calculateBmi(latestWeightKg, heightCm);
        final category = _bmiCategory(bmi);
        final badgeColor = _badgeColorForCategory(category);
        final goalText = _goalText(targetWeight, latestWeightKg, weightUnit);

        return Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                              category,
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
                        'Based on your height and latest weight',
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
                    ],
                  ),
                ),
              ],
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

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    }
    if (bmi < 25.0) {
      return 'Normal';
    }
    if (bmi < 30.0) {
      return 'Overweight';
    }
    return 'Obese';
  }

  Color _badgeColorForCategory(String category) {
    return switch (category) {
      'Underweight' => Colors.blue,
      'Normal' => Colors.green,
      'Overweight' => Colors.orange,
      'Obese' => Colors.red,
      _ => Colors.blue,
    };
  }

  String _goalText(
    double? targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
  ) {
    if (targetWeight == null) {
      return 'Goal not set';
    }

    if (currentWeightKg <= targetWeight) {
      return 'Goal achieved! 🎉';
    }

    final difference = currentWeightKg - targetWeight;
    final displayedDifference = unit == MeasurementUnit.imperial
        ? kgToLbs(difference)
        : difference;
    final unitLabel = unit == MeasurementUnit.imperial ? 'lbs' : 'kg';

    return '${displayedDifference.toStringAsFixed(1)} $unitLabel to target';
  }
}
