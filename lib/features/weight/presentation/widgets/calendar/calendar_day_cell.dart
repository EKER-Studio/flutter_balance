import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Reusable calendar day cell widget representing a single day in the monthly grid.
class CalendarDayCell extends StatelessWidget {
  /// The date represented by this cell.
  final DateTime date;

  /// Day number (1-31).
  final int dayNumber;

  /// Entries recorded on this date.
  final List<WeightEntry> entries;

  /// Whether this day is today.
  final bool isToday;

  /// Whether this day is selected.
  final bool isSelected;

  /// Whether this day is in the future.
  final bool isFuture;

  /// Whether the user reached their target weight goal on this day.
  final bool isGoalAchieved;

  /// Callback when this cell is tapped.
  final VoidCallback onTap;

  /// Creates a [CalendarDayCell].
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.entries,
    required this.isToday,
    required this.isSelected,
    this.isFuture = false,
    this.isGoalAchieved = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMd(locale).format(date);

    final hasEntries = entries.isNotEmpty;
    final entriesCountLabel = !hasEntries
        ? l10n.noEntriesLabel
        : (entries.length == 1
              ? l10n.singleEntry
              : l10n.multipleEntries(entries.length));

    final futureSuffix = isFuture ? ', ${l10n.futureDateSuffix}' : '';
    final goalSuffix = isGoalAchieved ? ', ${l10n.goalAchieved}' : '';

    final semanticsLabel =
        '$dateLabel, $entriesCountLabel$goalSuffix$futureSuffix${isSelected ? ', ${l10n.selectedSuffix}' : ''}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: SizedBox.expand(
              child: Opacity(
                opacity: isFuture ? 0.40 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? cs.primary : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: cs.primary, width: 1.0)
                        : null,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? cs.onPrimary
                                : (isToday ? cs.primary : cs.onSurface),
                          ),
                        ),
                      ),
                      // Indicator dots for entries
                      if (hasEntries)
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              entries.length > 3 ? 3 : entries.length,
                              (index) => Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? cs.onPrimary : cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Goal Achievement Star Badge
                      if (isGoalAchieved)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Icon(
                            Icons.star,
                            size: 10,
                            color: isSelected ? cs.onPrimary : cs.tertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
