import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_initial_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_target_weight.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_units_height.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/dev/preview/preview_support.dart';

/// Shows the units and height step with a metric height.
@Preview(
  name: 'Onboarding - Height Metric',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget onboardingHeightMetricPreview() => const StepUnitsHeight(
  initialUnit: MeasurementUnit.metric,
  initialHeightCm: 173,
  isCurrentPage: false,
  onNext: _ignoreHeightSubmission,
);

/// Shows the units and height step with an imperial height.
@Preview(
  name: 'Onboarding - Height Imperial',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget onboardingHeightImperialPreview() => const StepUnitsHeight(
  initialUnit: MeasurementUnit.imperial,
  initialHeightCm: 173,
  isCurrentPage: false,
  onNext: _ignoreHeightSubmission,
);

/// Shows the initial-weight step with a representative measurement.
@Preview(
  name: 'Onboarding - Initial Weight',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget onboardingInitialWeightPreview() => StepInitialWeight(
  unit: MeasurementUnit.metric,
  initialWeightKg: 76.4,
  initialTimestamp: DateTime(2026, 1, 15, 8),
  onNext: _ignoreInitialWeightSubmission,
);

/// Shows the target-weight step with a goal and progress delta.
@Preview(
  name: 'Onboarding - Target Weight',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget onboardingTargetWeightPreview() => const StepTargetWeight(
  unit: MeasurementUnit.metric,
  initialTargetWeightKg: 72,
  initialGoalMode: WeightGoalMode.lose,
  initialWeightKg: 76.4,
  onNext: _ignoreTargetWeightSubmission,
);

void _ignoreHeightSubmission(MeasurementUnit unit, double heightCm) {}

void _ignoreInitialWeightSubmission(double weightKg, DateTime timestamp) {}

void _ignoreTargetWeightSubmission(
  double? targetWeightKg,
  WeightGoalMode goalMode,
) {}
