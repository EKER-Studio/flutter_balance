import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/goal_progress_bar.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  /// Pumps [child] inside a [MaterialApp] with the app's localization delegates
  /// and a [Scaffold] (the [GoalProgressBar] uses an [InkWell], which requires a
  /// [Material] ancestor).
  Future<void> pumpWithL10n(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('GoalProgressBar — lose mode', () {
    testWidgets('shows remaining weight when current is above target', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 70.0,
          currentWeightKg: 75.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.lose,
        ),
      );

      expect(find.text('Goal: 70.0 kg'), findsOneWidget);
      expect(find.text('Remaining: 5.0 kg'), findsOneWidget);
      // Not achieved → progress bar is rendered as a FractionallySizedBox.
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('shows "Goal achieved!" when current is at or below target', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 70.0,
          currentWeightKg: 68.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.lose,
        ),
      );

      expect(find.text('Goal achieved!'), findsOneWidget);
    });
  });

  group('GoalProgressBar — gain mode', () {
    testWidgets('shows remaining weight when current is below target', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 70.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.gain,
        ),
      );

      expect(find.text('Goal: 80.0 kg'), findsOneWidget);
      expect(find.text('Remaining: 10.0 kg'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('shows "Goal achieved!" when current is at or above target', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 85.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.gain,
        ),
      );

      expect(find.text('Goal achieved!'), findsOneWidget);
    });

    testWidgets('converts remaining weight to pounds in imperial mode', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 70.0,
          unit: MeasurementUnit.imperial,
          unitLabel: 'lb',
          goalMode: WeightGoalMode.gain,
        ),
      );

      // 10 kg ≈ 22.0 lb (kgToLbs(10) = 22.0462 → '22.0').
      expect(find.text('Remaining: 22.0 lb'), findsOneWidget);
    });
  });

  group('GoalProgressBar — maintain mode', () {
    testWidgets('shows deviation when current is outside the stable band', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 85.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.maintain,
        ),
      );

      // current (85) > target (80) → sign is '+' and difference is 5.0 kg.
      expect(find.text('Deviation: +5.0 kg'), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('shows stable weight when current is within the band', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 80.5,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.maintain,
        ),
      );

      // 0.5 kg deviation is within the 1.0 kg threshold → stable.
      expect(find.text('Weight stable (±1.0 kg)'), findsOneWidget);
    });

    testWidgets('uses the imperial stable band label in imperial mode', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: 80.0,
          currentWeightKg: 80.0,
          unit: MeasurementUnit.imperial,
          unitLabel: 'lb',
          goalMode: WeightGoalMode.maintain,
        ),
      );

      expect(find.text('Weight stable (±2.0 lb)'), findsOneWidget);
    });
  });

  group('GoalProgressBar — no target set', () {
    testWidgets('shows "Not set" / "Set goal" and collapses the progress bar', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        const GoalProgressBar(
          targetWeightKg: null,
          currentWeightKg: 72.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
        ),
      );

      // goalTargetStr is "Not set", rendered via goalWeightLabel → "Goal: Not set".
      expect(find.text('Goal: Not set'), findsOneWidget);
      expect(find.text('Set goal'), findsOneWidget);
      // progress is 0.0 → the bar collapses to a SizedBox, no FractionallySizedBox.
      expect(find.byType(FractionallySizedBox), findsNothing);
    });
  });

  group('GoalProgressBar — interaction', () {
    testWidgets('invokes onTap when tapped', (tester) async {
      var tapped = false;
      await pumpWithL10n(
        tester,
        GoalProgressBar(
          targetWeightKg: 70.0,
          currentWeightKg: 75.0,
          unit: MeasurementUnit.metric,
          unitLabel: 'kg',
          goalMode: WeightGoalMode.lose,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(GoalProgressBar));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
