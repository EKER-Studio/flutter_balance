import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/core/models/measurement_unit.dart';
import 'package:pure_weight/core/utils/unit_converter.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';
import 'package:pure_weight/presentation/bloc/settings/bmi_category.dart';
import 'package:pure_weight/presentation/widgets/target_weight_dialog.dart';

/// A health summary card displaying current BMI, last updated status, category badge, and weight goal actions.
class HealthSummaryCard extends StatelessWidget {
  /// The latest recorded weight in kilograms.
  final double latestWeightKg;

  /// Optional date of the latest recorded weight measurement.
  final DateTime? lastUpdated;

  /// Creates a [HealthSummaryCard] with [latestWeightKg] and optional [lastUpdated].
  const HealthSummaryCard({
    super.key,
    required this.latestWeightKg,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsBloc, AppSettingsState>(
      builder: (context, state) {
        final heightCm = state.height;
        final targetWeight = state.targetWeight;
        final weightUnit = state.measurementUnit;
        final l10n = AppLocalizations.of(context);
        final bmi = _calculateBmi(latestWeightKg, heightCm);
        final category = bmi.isFinite ? getBmiCategory(bmi) : null;
        final badgeColor = category != null
            ? _badgeColorForCategory(context, category)
            : Theme.of(context).colorScheme.primary;

        final lastUpdateText = _formatLastUpdated(context, lastUpdated, l10n);

        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.bmi,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastUpdateText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (category != null)
                      Semantics(
                        label: 'Kategoria BMI: ${_interpretBmi(category, l10n)}',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: badgeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _interpretBmi(category, l10n),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      label: 'Wskaźnik BMI: ${bmi.isFinite ? bmi.toStringAsFixed(1) : "brak podanego wzrostu"} kg/m²',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            bmi.isFinite ? bmi.toStringAsFixed(1) : '—',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'kg/m²',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildGoalButton(context, targetWeight, weightUnit, l10n),
                  ],
                ),
                if (targetWeight != null) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: '${l10n.weightGoal}: ${_goalText(targetWeight, latestWeightKg, weightUnit, l10n)}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.weightGoal,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          _goalText(targetWeight, latestWeightKg, weightUnit, l10n),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalButton(
    BuildContext context,
    double? targetWeightKg,
    MeasurementUnit unit,
    AppLocalizations l10n,
  ) {
    final buttonLabel = targetWeightKg == null ? l10n.setWeightGoal : l10n.weightGoal;

    return Semantics(
      button: true,
      label: buttonLabel,
      child: TextButton.icon(
        onPressed: () => _openTargetWeightDialog(context, targetWeightKg, unit),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(
          buttonLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Future<void> _openTargetWeightDialog(
    BuildContext context,
    double? targetWeightKg,
    MeasurementUnit unit,
  ) async {
    final displayValue = targetWeightKg != null
        ? (unit == MeasurementUnit.imperial ? kgToLbs(targetWeightKg) : targetWeightKg)
        : null;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => TargetWeightDialog(
        currentValue: displayValue,
        unit: unit,
      ),
    );

    if (result != null && context.mounted) {
      final targetKg = unit == MeasurementUnit.imperial ? lbsToKg(result) : result;
      context.read<AppSettingsBloc>().add(TargetWeightChanged(targetKg));
    }
  }

  String _formatLastUpdated(
    BuildContext context,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    if (date == null) {
      return l10n.bmiSubtitle;
    }
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      return l10n.lastUpdatedToday;
    }
    final formattedDate = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    return l10n.lastUpdatedDate(formattedDate);
  }

  double _calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0) {
      return double.nan;
    }
    final heightInMeters = heightCm / 100;
    return weightKg / (heightInMeters * heightInMeters);
  }

  Color _badgeColorForCategory(BuildContext context, BmiCategory category) {
    final cs = Theme.of(context).colorScheme;
    return switch (category) {
      BmiCategory.underweight => cs.primary,
      BmiCategory.normal => cs.tertiary,
      BmiCategory.overweight => cs.secondary,
      BmiCategory.obese => cs.error,
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
    double targetWeight,
    double currentWeightKg,
    MeasurementUnit unit,
    AppLocalizations l10n,
  ) {
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
}
