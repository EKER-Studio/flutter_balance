import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

/// A service that synchronizes the user's latest weight data and goal progression
/// with native home screen widgets on iOS (WidgetKit) and Android (AppWidgetProvider).
class WidgetSyncService {
  static const String appGroupId = 'group.com.ekerstudio.balance';
  static const String androidWidgetName = 'BalanceAppWidgetProvider';
  static const String androidFullWidgetName = 'BalanceFullAppWidgetProvider';
  static const String iOSWidgetName = 'BalanceWidget';

  /// Global singleton instance of the widget synchronizer.
  static WidgetSyncService instance = const WidgetSyncService();

  const WidgetSyncService();

  /// Initializes the widget integration and configures the App Group identifier.
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to initialize WidgetSyncService',
        fatal: false,
      );
    }
  }

  /// Pushes latest weight data and goal metrics to native widget storage.
  ///
  /// @param entries Full list of user's recorded weight entries.
  /// @param targetWeight Optional configured goal weight in kg.
  /// @param heightCm Optional user height in centimeters for BMI computation.
  /// @param goalMode Active goal mode (lose, maintain, gain).
  /// @param themeMode App theme mode (system, light, dark).
  /// @param isDarkMode Whether dark theme is currently active.
  Future<void> updateWidgetData({
    required List<WeightEntry> entries,
    double? targetWeight,
    double? heightCm,
    WeightGoalMode goalMode = WeightGoalMode.lose,
    MeasurementUnit unit = MeasurementUnit.metric,
    AppThemeMode themeMode = AppThemeMode.system,
    bool isDarkMode = false,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('theme_mode', themeMode.name);
      await HomeWidget.saveWidgetData<bool>('is_dark_mode', isDarkMode);

      if (entries.isEmpty) {
        await HomeWidget.saveWidgetData<bool>('has_data', false);
        await HomeWidget.saveWidgetData<String>(
          'header_title',
          'Ostatni pomiar',
        );
        await HomeWidget.saveWidgetData<String>('current_weight', '--');
        await HomeWidget.saveWidgetData<String>('unit', unitLabelFor(unit));
        await HomeWidget.saveWidgetData<String>('delta_text', '');
        await HomeWidget.saveWidgetData<bool>('delta_is_loss', false);
        await HomeWidget.saveWidgetData<String>('delta_type', '');
        await HomeWidget.saveWidgetData<String>('target_weight', '');
        await HomeWidget.saveWidgetData<int>('goal_progress_pct', 0);
        await HomeWidget.saveWidgetData<bool>('is_goal_achieved', false);
        await HomeWidget.saveWidgetData<String>('goal_status_text', '');
        await HomeWidget.saveWidgetData<String>('bmi_value', '');
        await HomeWidget.saveWidgetData<String>('bmi_category', '');
        await HomeWidget.saveWidgetData<String>('bmi_category_label', '');
        await HomeWidget.saveWidgetData<String>('goal_mode', goalMode.name);
        await HomeWidget.saveWidgetData<String>('last_entry_date', '');
      } else {
        final sorted = entries.toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        final latest = sorted.last;
        final latestWeightDisplay = unit == MeasurementUnit.imperial
            ? kgToLbs(latest.weightKg)
            : latest.weightKg;
        final unitLabel = unitLabelFor(unit);

        String deltaText = '';
        bool deltaIsLoss = true;
        String deltaType = '';
        if (sorted.length > 1) {
          final previous = sorted[sorted.length - 2];
          final deltaKg = latest.weightKg - previous.weightKg;
          final deltaDisplay = unit == MeasurementUnit.imperial
              ? kgToLbs(deltaKg)
              : deltaKg;
          if (deltaDisplay < -0.05) {
            deltaType = 'loss';
            deltaIsLoss = true;
            deltaText = '${deltaDisplay.toStringAsFixed(1)} $unitLabel';
          } else if (deltaDisplay > 0.05) {
            deltaType = 'gain';
            deltaIsLoss = false;
            deltaText = '+${deltaDisplay.toStringAsFixed(1)} $unitLabel';
          } else {
            deltaType = 'neutral';
            deltaIsLoss = false;
            deltaText = '0.0 $unitLabel';
          }
        }

        int goalProgressPct = 0;
        String targetWeightStr = '';
        bool isGoalAchieved = false;
        String goalStatusText = '';
        if (targetWeight != null) {
          final targetDisplay = unit == MeasurementUnit.imperial
              ? kgToLbs(targetWeight)
              : targetWeight;
          targetWeightStr = '${targetDisplay.toStringAsFixed(1)} $unitLabel';

          final first = sorted.first;
          goalProgressPct = _calculateProgressPct(
            startKg: first.weightKg,
            currentKg: latest.weightKg,
            targetKg: targetWeight,
            goalMode: goalMode,
            unit: unit,
          );
          isGoalAchieved = goalProgressPct >= 100;
          goalStatusText = isGoalAchieved
              ? 'Cel osiągnięty!'
              : '$goalProgressPct%';
        }

        String bmiValue = '';
        String bmiCategory = '';
        String bmiCategoryLabel = '';
        if (heightCm != null && heightCm > 0) {
          final heightM = heightCm / 100.0;
          final bmi = latest.weightKg / (heightM * heightM);
          if (bmi.isFinite) {
            bmiValue = bmi.toStringAsFixed(1);
            final category = BmiCategory.fromBmi(bmi);
            bmiCategory = category.name;
            bmiCategoryLabel = _bmiCategoryLabel(category);
          }
        }

        final now = DateTime.now();
        final isToday =
            latest.dateTime.year == now.year &&
            latest.dateTime.month == now.month &&
            latest.dateTime.day == now.day;
        final timeStr = DateFormat('HH:mm').format(latest.dateTime);
        final formattedDate = isToday
            ? 'Dzisiaj, $timeStr'
            : '${DateFormat('d MMM').format(latest.dateTime)} • $timeStr';

        await HomeWidget.saveWidgetData<bool>('has_data', true);
        await HomeWidget.saveWidgetData<String>(
          'header_title',
          'Ostatni pomiar',
        );
        await HomeWidget.saveWidgetData<String>(
          'current_weight',
          latestWeightDisplay.toStringAsFixed(1),
        );
        await HomeWidget.saveWidgetData<String>('unit', unitLabel);
        await HomeWidget.saveWidgetData<String>('delta_text', deltaText);
        await HomeWidget.saveWidgetData<bool>('delta_is_loss', deltaIsLoss);
        await HomeWidget.saveWidgetData<String>('delta_type', deltaType);
        await HomeWidget.saveWidgetData<String>(
          'target_weight',
          targetWeightStr,
        );
        await HomeWidget.saveWidgetData<int>(
          'goal_progress_pct',
          goalProgressPct,
        );
        await HomeWidget.saveWidgetData<bool>(
          'is_goal_achieved',
          isGoalAchieved,
        );
        await HomeWidget.saveWidgetData<String>(
          'goal_status_text',
          goalStatusText,
        );
        await HomeWidget.saveWidgetData<String>('bmi_value', bmiValue);
        await HomeWidget.saveWidgetData<String>('bmi_category', bmiCategory);
        await HomeWidget.saveWidgetData<String>(
          'bmi_category_label',
          bmiCategoryLabel,
        );
        await HomeWidget.saveWidgetData<String>('goal_mode', goalMode.name);
        await HomeWidget.saveWidgetData<String>(
          'last_entry_date',
          formattedDate,
        );
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      await HomeWidget.updateWidget(
        name: androidFullWidgetName,
        androidName: androidFullWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to update native widgets',
        fatal: false,
      );
    }
  }

  /// Clears widget storage on database wipe or logout.
  Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<bool>('has_data', false);
      await HomeWidget.saveWidgetData<String>('current_weight', '--');
      await HomeWidget.saveWidgetData<String>('delta_text', '');
      await HomeWidget.saveWidgetData<String>('target_weight', '');
      await HomeWidget.saveWidgetData<int>('goal_progress_pct', 0);
      await HomeWidget.saveWidgetData<bool>('is_goal_achieved', false);
      await HomeWidget.saveWidgetData<String>('goal_status_text', '');
      await HomeWidget.saveWidgetData<String>('bmi_value', '');
      await HomeWidget.saveWidgetData<String>('bmi_category_label', '');
      await HomeWidget.saveWidgetData<String>('last_entry_date', '');

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      await HomeWidget.updateWidget(
        name: androidFullWidgetName,
        androidName: androidFullWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e, stack) {
      AppCrashReporter.recordError(
        e,
        stack,
        reason: 'Failed to clear widget data',
        fatal: false,
      );
    }
  }

  static String _bmiCategoryLabel(BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return 'Niedowaga';
      case BmiCategory.normal:
        return 'W normie';
      case BmiCategory.overweight:
        return 'Nadwaga';
      case BmiCategory.obeseClass1:
        return 'Otyłość I';
      case BmiCategory.obeseClass2:
        return 'Otyłość II';
      case BmiCategory.obeseClass3:
        return 'Otyłość III';
    }
  }

  static int _calculateProgressPct({
    required double startKg,
    required double currentKg,
    required double targetKg,
    required WeightGoalMode goalMode,
    required MeasurementUnit unit,
  }) {
    switch (goalMode) {
      case WeightGoalMode.lose:
        if (currentKg <= targetKg) return 100;
        final totalNeeded = startKg - targetKg;
        if (totalNeeded <= 0) return 100;
        final achieved = startKg - currentKg;
        if (achieved <= 0) return 0;
        return ((achieved / totalNeeded) * 100).clamp(0.0, 100.0).round();

      case WeightGoalMode.gain:
        if (currentKg >= targetKg) return 100;
        final totalNeeded = targetKg - startKg;
        if (totalNeeded <= 0) return 100;
        final achieved = currentKg - startKg;
        if (achieved <= 0) return 0;
        return ((achieved / totalNeeded) * 100).clamp(0.0, 100.0).round();

      case WeightGoalMode.maintain:
        final diff = (currentKg - targetKg).abs();
        final thresholdKg = unit == MeasurementUnit.imperial
            ? lbsToKg(2.2)
            : 1.0;
        if (diff <= thresholdKg) return 100;
        final maxDiff = unit == MeasurementUnit.imperial ? 10.0 : 5.0;
        final progress = (1.0 - (diff / maxDiff)).clamp(0.0, 1.0);
        return (progress * 100).round();
    }
  }
}
