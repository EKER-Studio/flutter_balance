import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A presentational widget displaying the latest recorded weight and its timestamp.
class LatestMeasurementInfo extends StatelessWidget {
  /// The latest weight value already converted to the active display unit.
  final double displayWeight;

  /// The measurement unit symbol (e.g., 'kg' or 'lb').
  final String unitLabel;

  /// The timestamp when the weight measurement was recorded.
  final DateTime? lastUpdated;

  /// The difference in weight compared to yesterday's measurement (if available).
  final double? deltaFromYesterday;

  const LatestMeasurementInfo({
    super.key,
    required this.displayWeight,
    required this.unitLabel,
    this.lastUpdated,
    this.deltaFromYesterday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.lastMeasurementLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayWeight.toStringAsFixed(1),
                style: textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unitLabel,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (deltaFromYesterday != null) ...[
                const SizedBox(width: 8),
                _buildDeltaIndicator(context, deltaFromYesterday!),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(context, lastUpdated, l10n),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(
    BuildContext context,
    DateTime? date,
    AppLocalizations l10n,
  ) {
    if (date == null) {
      return '';
    }
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final timeStr = DateFormat.jm(
      Localizations.localeOf(context).toString(),
    ).format(date);

    if (isToday) {
      return l10n.todayAtTime(timeStr);
    }
    final dateStr = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
    return '$dateStr • $timeStr';
  }

  Widget _buildDeltaIndicator(BuildContext context, double delta) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // We assume a negative delta (weight loss) is positive improvement
    final isImprovement = delta <= 0;

    final Color badgeBg = isImprovement
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.orange.withValues(alpha: 0.15);
    final Color badgeFg = isImprovement
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.orange.shade300 : Colors.orange.shade700);

    final String sign = delta > 0 ? '+' : '';
    final String valStr = delta.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l10n.vsYesterday('$sign$valStr $unitLabel'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: badgeFg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
