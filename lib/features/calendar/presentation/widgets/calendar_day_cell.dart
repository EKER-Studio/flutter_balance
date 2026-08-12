import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A widget representing a single day cell in the monthly calendar grid.
class CalendarDayCell extends StatelessWidget {
  /// The date represented by this cell.
  final DateTime date;

  /// The day of the month (1-31).
  final int dayNumber;

  /// The list of [WeightEntry] records for this date.
  final List<WeightEntry> entries;

  /// Whether this date corresponds to the current day.
  final bool isToday;

  /// Whether this date is currently selected by the user.
  final bool isSelected;

  /// Whether this date is in the future.
  final bool isFuture;

  /// Whether the user reached their target weight goal on this day.
  final bool isGoalAchieved;

  /// The callback invoked when the cell is tapped.
  ///
  /// Null if the cell is disabled.
  final VoidCallback? onTap;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dayNumber,
    required this.entries,
    required this.isToday,
    required this.isSelected,
    this.isFuture = false,
    this.isGoalAchieved = false,
    this.onTap,
  });

  static String? _cachedLocale;
  static DateFormat? _cachedFormatter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    if (_cachedLocale != locale || _cachedFormatter == null) {
      _cachedLocale = locale;
      _cachedFormatter = DateFormat.yMMMMd(locale);
    }
    final dateLabel = _cachedFormatter!.format(date);

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
      excludeSemantics: true,
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
                child: Badge(
                  isLabelVisible: isGoalAchieved,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                      ? Colors.green.shade800
                      : Colors.green.shade300,
                  padding: const EdgeInsets.all(3),
                  label: Icon(
                    Icons.star,
                    size: 10,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : const Color(0xFF1B5E20),
                  ),
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
                                    color: isSelected
                                        ? cs.onPrimary
                                        : cs.primary,
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
