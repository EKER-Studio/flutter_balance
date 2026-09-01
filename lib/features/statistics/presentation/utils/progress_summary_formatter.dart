import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/services/milestone_calculator.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/statistics_content_section.dart';
import 'package:balance/features/weight/domain/bmi_category.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/utils/bmi_category_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Helper formatting a rich, human-readable, and motivational shareable progress summary text.
class ProgressSummaryFormatter {
  const ProgressSummaryFormatter._();

  /// Builds a human-readable, inspirational progress summary.
  ///
  /// @param entries List of recorded weight entries.
  /// @param targetWeight Optional goal weight in kg.
  /// @param goalMode Active goal mode.
  /// @param unit Active measurement unit.
  /// @param l10n Localized strings provider.
  /// @param heightCm Optional user height in cm for BMI calculation.
  /// @param paceWindowDays Pace calculation window in days.
  /// @return Formatted plain text string suitable for sharing.
  static String format({
    required List<WeightEntry> entries,
    double? targetWeight,
    WeightGoalMode goalMode = WeightGoalMode.lose,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
    double? heightCm,
    int paceWindowDays = 30,
    DateTime? now,
  }) {
    if (entries.isEmpty) return '';

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final unitLabel = unitLabelFor(unit);
    final first = sorted.first;
    final latest = sorted.last;
    final currentDate = now ?? DateTime.now();

    final startWeightDisplay = _formatValue(first.weightKg, unit);
    final latestWeightDisplay = _formatValue(latest.weightKg, unit);
    final totalChangeKg = latest.weightKg - first.weightKg;
    final totalChangeDisplay = _formatValue(totalChangeKg.abs(), unit);
    final totalChangePercent = first.weightKg > 0
        ? ((totalChangeKg / first.weightKg) * 100).abs().toStringAsFixed(1)
        : null;
    final isLoss = totalChangeKg < 0;
    final changeSign = isLoss ? '-' : (totalChangeKg > 0 ? '+' : '');
    final trendEmoji = totalChangeKg < 0
        ? '📉'
        : (totalChangeKg > 0 ? '📈' : '➡️');

    final buffer = StringBuffer();
    buffer.writeln('📊 Balance — ${l10n.totalProgress}');
    buffer.writeln(
      '📅 ${DateFormat.yMMMMd(l10n.localeName).format(currentDate)}',
    );
    buffer.writeln('');

    // --- Section 1: Progress & Goal ---
    buffer.writeln('⚖️ ${l10n.summaryProgressTitle}');
    final startDateFormatted = DateFormat.yMMMd(
      l10n.localeName,
    ).format(first.dateTime);
    final latestDateFormatted = DateFormat.yMMMd(
      l10n.localeName,
    ).format(latest.dateTime);

    buffer.writeln(
      '• ${l10n.summaryStartLabel}: $startWeightDisplay $unitLabel ($startDateFormatted)',
    );
    buffer.writeln(
      '• ${l10n.summaryCurrentLabel}: $latestWeightDisplay $unitLabel ($latestDateFormatted)',
    );

    final pctText = totalChangePercent != null
        ? ' ($changeSign$totalChangePercent%)'
        : '';
    buffer.writeln(
      '• ${l10n.summaryChangeLabel}: $changeSign$totalChangeDisplay $unitLabel$pctText $trendEmoji',
    );

    if (targetWeight != null) {
      final targetDisplay = _formatValue(targetWeight, unit);
      final remainingKg = (latest.weightKg - targetWeight).abs();
      final remainingDisplay = _formatValue(remainingKg, unit);

      final String goalSuffix;
      if (goalMode == WeightGoalMode.maintain) {
        final thresholdKg = unit == MeasurementUnit.imperial
            ? lbsToKg(2.2)
            : 1.0;
        final rangeDisplay = unit == MeasurementUnit.imperial
            ? '2.0 lb'
            : '1.0 kg';
        final isMaintained = remainingKg <= thresholdKg;
        goalSuffix = isMaintained
            ? l10n.goalWeightMaintained(rangeDisplay)
            : l10n.goalWeightDeviation(
                '${latest.weightKg >= targetWeight ? '+' : '-'}$remainingDisplay $unitLabel',
              );
      } else {
        final isAchieved = goalMode == WeightGoalMode.gain
            ? latest.weightKg >= targetWeight
            : latest.weightKg <= targetWeight;
        goalSuffix = isAchieved
            ? '${l10n.goalAchieved} 🎉'
            : l10n.remainingWeightLabel('$remainingDisplay $unitLabel');
      }

      buffer.writeln(
        '• ${l10n.targetWeight}: $targetDisplay $unitLabel ($goalSuffix)',
      );
    }

    final weeklyPace = StatisticsContentSection.calculateWeeklyPace(
      entries,
      windowDays: paceWindowDays,
      now: currentDate,
    );
    if (weeklyPace != null) {
      final paceDisplay = _formatValue(weeklyPace.abs(), unit);
      final paceSign = weeklyPace < 0 ? '-' : (weeklyPace > 0 ? '+' : '');
      final paceTrendEmoji = weeklyPace < 0
          ? '📉'
          : (weeklyPace > 0 ? '📈' : '➡️');
      final paceWindowText = l10n.paceWindowDays(paceWindowDays).toLowerCase();
      buffer.writeln(
        '• ${l10n.summaryPaceLabel}: $paceSign$paceDisplay $unitLabel / ${l10n.week.toLowerCase()} ($paceWindowText) $paceTrendEmoji',
      );
    }

    if (heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      final bmi = latest.weightKg / (heightM * heightM);
      final category = BmiCategory.fromBmi(bmi);
      buffer.writeln(
        '• BMI: ${bmi.toStringAsFixed(1)} (${category.localizedName(l10n)})',
      );
    }

    // --- Section 2: Range & Statistics ---
    buffer.writeln('');
    buffer.writeln('📈 ${l10n.summaryRangeTitle}');
    final maxEntry = entries.reduce((a, b) => a.weightKg > b.weightKg ? a : b);
    final maxDisplay = _formatValue(maxEntry.weightKg, unit);
    final maxDateText = DateFormat.yMMMd(
      l10n.localeName,
    ).format(maxEntry.dateTime);
    buffer.writeln('• ${l10n.highest}: $maxDisplay $unitLabel ($maxDateText)');

    final minEntry = entries.reduce((a, b) => a.weightKg < b.weightKg ? a : b);
    final minDisplay = _formatValue(minEntry.weightKg, unit);
    final minDateText = DateFormat.yMMMd(
      l10n.localeName,
    ).format(minEntry.dateTime);
    buffer.writeln('• ${l10n.lowest}: $minDisplay $unitLabel ($minDateText)');

    final weights = entries.map((e) => e.weightKg).toList();
    final avgWeightKg = weights.reduce((a, b) => a + b) / weights.length;
    final avgDisplay = _formatValue(avgWeightKg, unit);
    buffer.writeln('• ${l10n.averageWeight}: $avgDisplay $unitLabel');
    buffer.writeln('• ${l10n.summaryTotalMeasurements}: ${entries.length}');

    // --- Section 3: Habits & Consistency ---
    buffer.writeln('');
    buffer.writeln('🔥 ${l10n.summaryHabitsTitle}');
    final streak = _calculateStreak(entries, currentDate);
    final bestStreak = _calculateBestStreak(entries);
    final compliancePct = _calculateTotalCompliance(entries, currentDate);
    buffer.writeln(
      '• ${l10n.currentStreak}: ${l10n.streakDays(streak)} ${streak > 0 ? "🔥" : ""}',
    );
    buffer.writeln('• ${l10n.bestStreak}: ${l10n.streakDays(bestStreak)}');
    buffer.writeln('• ${l10n.summaryConsistency}: $compliancePct%');

    final milestones = MilestoneCalculator.evaluate(
      entries: entries,
      targetWeight: targetWeight,
      heightCm: heightCm,
      goalMode: goalMode,
    );
    final unlockedCount = milestones.where((m) => m.isUnlocked).length;
    buffer.writeln(
      '• ${l10n.milestones}: $unlockedCount / ${milestones.length} 🏆',
    );

    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('📱 ${l10n.summaryAppFooter}');

    return buffer.toString().trim();
  }

  static int _calculateStreak(List<WeightEntry> entries, DateTime now) {
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet();

    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = DateTime(now.year, now.month, now.day - 1);

    if (!dates.contains(todayDate) && !dates.contains(yesterdayDate)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(todayDate) ? todayDate : yesterdayDate;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    return streak;
  }

  static int _calculateBestStreak(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;

    final dates =
        entries
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

    int best = 1;
    int current = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return best;
  }

  static int _calculateTotalCompliance(
    List<WeightEntry> entries,
    DateTime now,
  ) {
    if (entries.isEmpty) return 0;

    final firstDate = entries
        .map((e) => e.dateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);

    int totalDays = today.difference(start).inDays + 1;
    if (totalDays <= 0) totalDays = 1;

    final loggedDays = entries
        .map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day))
        .toSet()
        .length;
    return ((loggedDays / totalDays) * 100).round().clamp(0, 100);
  }

  static String _formatValue(double weightKg, MeasurementUnit unit) {
    final display = unit == MeasurementUnit.imperial
        ? kgToLbs(weightKg)
        : weightKg;
    return display.toStringAsFixed(1);
  }
}
