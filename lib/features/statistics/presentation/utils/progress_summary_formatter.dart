import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Helper formatting a shareable progress summary text.
class ProgressSummaryFormatter {
  const ProgressSummaryFormatter._();

  /// Builds a human-readable, inspirational progress summary.
  ///
  /// @param entries List of recorded weight entries.
  /// @param targetWeight Optional goal weight in kg.
  /// @param goalMode Active goal mode.
  /// @param unit Active measurement unit.
  /// @param l10n Localized strings provider.
  /// @return Formatted plain text string suitable for sharing.
  static String format({
    required List<WeightEntry> entries,
    double? targetWeight,
    WeightGoalMode goalMode = WeightGoalMode.lose,
    required MeasurementUnit unit,
    required AppLocalizations l10n,
  }) {
    if (entries.isEmpty) return '';

    final sorted = entries.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final unitLabel = unitLabelFor(unit);
    final first = sorted.first;
    final latest = sorted.last;
    final startWeightDisplay = _formatValue(first.weightKg, unit);
    final latestWeightDisplay = _formatValue(latest.weightKg, unit);
    final totalChangeKg = latest.weightKg - first.weightKg;
    final totalChangeDisplay = _formatValue(totalChangeKg.abs(), unit);
    final isLoss = totalChangeKg <= 0;

    final buffer = StringBuffer();
    buffer.writeln('📊 Balance — ${l10n.totalProgress}');
    buffer.writeln('');
    buffer.writeln(
      '🏁 ${l10n.sinceEntryDate(DateFormat.yMMMd(l10n.localeName).format(first.dateTime))}: $startWeightDisplay $unitLabel',
    );
    buffer.writeln(
      '⚖️ ${l10n.currentWeightLabel}: $latestWeightDisplay $unitLabel (${isLoss ? "-" : "+"}$totalChangeDisplay $unitLabel)',
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
            ? l10n.goalAchieved
            : l10n.remainingWeightLabel('$remainingDisplay $unitLabel');
      }

      buffer.writeln(
        '🎯 ${l10n.targetWeight}: $targetDisplay $unitLabel ($goalSuffix)',
      );
    }

    buffer.writeln('');
    buffer.writeln('✨ Balance');

    return buffer.toString().trim();
  }

  static String _formatValue(double weightKg, MeasurementUnit unit) {
    final display = unit == MeasurementUnit.imperial
        ? kgToLbs(weightKg)
        : weightKg;
    return display.toStringAsFixed(1);
  }
}
