import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/bmi_badge.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/goal_progress_bar.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/latest_measurement_info.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_dialog.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/features/weight/presentation/widgets/bmi_legend_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

/// An integrated summary card displaying the latest weight, BMI, and goal progress.
class HealthSummaryCard extends StatelessWidget {
  /// The latest recorded weight in kilograms.
  final double latestWeightKg;

  /// An optional date of the latest recorded weight measurement.
  final DateTime? lastUpdated;

  /// Creates a [HealthSummaryCard].
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

        final bmi = (heightCm != null && heightCm > 0)
            ? state.calculateBmi(latestWeightKg)
            : double.nan;
        final category = bmi.isFinite ? BmiCategory.fromBmi(bmi) : null;

        final displayWeight = weightUnit == MeasurementUnit.imperial
            ? kgToLbs(latestWeightKg)
            : latestWeightKg;
        final unitLabel = unitLabelFor(weightUnit);

        final colorScheme = Theme.of(context).colorScheme;

        final isLandscapePhone =
            MediaQuery.of(context).orientation == Orientation.landscape &&
            MediaQuery.sizeOf(context).height < 500;

        final semanticsLabel = [
          '${l10n.lastMeasurementLabel}: ${displayWeight.toStringAsFixed(1)} $unitLabel',
          if (category != null)
            '${category.localizedName(l10n)}, ${l10n.bmiValueShortLabel(bmi.toStringAsFixed(1))}',
          if (targetWeight != null)
            l10n.goalWeightLabel(
              '${(weightUnit == MeasurementUnit.imperial ? kgToLbs(targetWeight) : targetWeight).toStringAsFixed(1)} $unitLabel',
            ),
        ].join('. ');

        return Semantics(
          container: true,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                AppAnalytics.logTodayLatestWeightTapped(
                                  weight: displayWeight,
                                  unit: unitLabel,
                                );
                              },
                              child: LatestMeasurementInfo(
                                displayWeight: displayWeight,
                                unitLabel: unitLabel,
                                lastUpdated: lastUpdated,
                              ),
                            ),
                          ),
                        ),
                        if (bmi.isFinite && !isLandscapePhone)
                          BmiBadge(
                            bmi: bmi,
                            category: category,
                            onTap: () => _openBmiLegendDialog(
                              context,
                              bmi: bmi,
                              category: category?.name ?? 'unknown',
                            ),
                          ),
                      ],
                    ),
                    if (targetWeight != null) ...[
                      const SizedBox(height: 16),
                      GoalProgressBar(
                        targetWeightKg: targetWeight,
                        currentWeightKg: latestWeightKg,
                        unit: weightUnit,
                        unitLabel: unitLabel,
                        onTap: () => _openTargetWeightDialog(
                          context,
                          targetWeight,
                          weightUnit,
                          latestWeightKg,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openBmiLegendDialog(
    BuildContext context, {
    required double bmi,
    required String category,
  }) {
    AppAnalytics.logTodayBmiBadgeTapped(bmi: bmi, category: category);
    AppAnalytics.logDialogBmiLegendOpened();
    showDialog<void>(
      context: context,
      builder: (context) => const BmiLegendDialog(),
    );
  }

  Future<void> _openTargetWeightDialog(
    BuildContext context,
    double? targetWeightKg,
    MeasurementUnit unit,
    double currentWeightKg,
  ) async {
    if (targetWeightKg != null) {
      AppAnalytics.logTodayGoalProgressBarTapped(
        targetWeightKg: targetWeightKg,
        currentWeightKg: currentWeightKg,
      );
    }
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => TargetWeightDialog(
        currentValueKg: targetWeightKg,
        measurementUnit: unit,
      ),
    );

    if (result != null && context.mounted) {
      if (result == 'clear') {
        AppAnalytics.logSettingsTargetWeightCleared();
        context.read<AppSettingsBloc>().add(const TargetWeightChanged(null));
      } else if (result is double) {
        final targetKg = unit == MeasurementUnit.imperial
            ? lbsToKg(result)
            : result;
        AppAnalytics.logSettingsTargetWeightSaved(targetKg);
        context.read<AppSettingsBloc>().add(TargetWeightChanged(targetKg));
      }
    }
  }
}
