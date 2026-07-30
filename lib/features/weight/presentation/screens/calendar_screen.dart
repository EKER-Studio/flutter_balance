import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';

/// Tab 2: Calendar Screen providing a monthly view with measurement status indicators.
class CalendarScreen extends StatefulWidget {
  /// Creates [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthYearStr = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabCalendar),
      ),
      body: SafeArea(
        child: BlocBuilder<WeightBloc, WeightState>(
          builder: (context, state) {
            final entries = switch (state) {
              WeightLoaded(:final entries) => entries,
              WeightError(:final entries) => entries,
              _ => <WeightEntry>[],
            };

            return ClampedLayout(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMonthHeader(context, monthYearStr),
                  const SizedBox(height: 16),
                  _buildDaysOfWeekHeader(context),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildCalendarGrid(context, entries),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, String monthYearStr) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              monthYearStr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysOfWeekHeader(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.E(locale);
    // Standard 7 days starting from Monday (e.g. 2026-01-05 was Monday)
    final mondayBase = DateTime(2026, 1, 5);
    final weekDays = List.generate(7, (i) => mondayBase.add(Duration(days: i)));

    return Row(
      children: weekDays.map((d) {
        return Expanded(
          child: Center(
            child: Text(
              format.format(d),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, List<WeightEntry> entries) {
    final firstDayOfMonth = _focusedMonth;
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );

    // DateTime.weekday: Mon=1, Sun=7. Calculate offset for Monday-first calendar.
    final startingOffset = firstDayOfMonth.weekday - 1;
    final totalCells = startingOffset + daysInMonth;

    // Group entries for this month by day
    final Map<int, List<WeightEntry>> entriesByDay = {};
    for (final e in entries) {
      if (e.dateTime.year == _focusedMonth.year &&
          e.dateTime.month == _focusedMonth.month) {
        entriesByDay.putIfAbsent(e.dateTime.day, () => []).add(e);
      }
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startingOffset) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startingOffset + 1;
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final dayEntries = entriesByDay[dayNumber] ?? const [];
        final isToday = DateUtils.isSameDay(date, DateTime.now());

        return _buildCalendarCell(
          context,
          date: date,
          dayNumber: dayNumber,
          entries: dayEntries,
          isToday: isToday,
        );
      },
    );
  }

  Widget _buildCalendarCell(
    BuildContext context, {
    required DateTime date,
    required int dayNumber,
    required List<WeightEntry> entries,
    required bool isToday,
  }) {
    final hasEntries = entries.isNotEmpty;
    final isMultiple = entries.length > 1;

    final cs = Theme.of(context).colorScheme;
    final backgroundColor = isToday
        ? cs.primaryContainer
        : hasEntries
            ? cs.secondaryContainer
            : cs.surfaceContainerLow;

    final textColor = isToday
        ? cs.onPrimaryContainer
        : hasEntries
            ? cs.onSecondaryContainer
            : cs.onSurface;

    return InkWell(
      onTap: () => _showDayDetailSheet(context, date, entries),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: cs.primary, width: 2)
              : hasEntries
                  ? null
                  : Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), width: 1),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: isToday || hasEntries ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
            const SizedBox(height: 4),
            if (hasEntries)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday ? cs.primary : cs.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (isMultiple) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isToday ? cs.primary : cs.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              )
            else
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(
    BuildContext context,
    DateTime date,
    List<WeightEntry> entries,
  ) {
    final l10n = AppLocalizations.of(context);
    final dateStr = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noEntriesToday,
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(sheetContext).colorScheme.outline,
                        ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      final timeStr = DateFormat.jm(
                        Localizations.localeOf(context).toString(),
                      ).format(e.dateTime);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(sheetContext).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.monitor_weight,
                            size: 18,
                            color: Theme.of(sheetContext).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                        subtitle: Text(
                          e.note != null && e.note!.isNotEmpty
                              ? '$timeStr • ${e.note}'
                              : timeStr,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            context.read<WeightBloc>().add(DeleteWeight(e.id));
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _showAddWeightSheetForDate(context, date);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addMeasurementForDate(dateStr)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddWeightSheetForDate(BuildContext context, DateTime targetDate) {
    // Preserve current time component if targetDate is today, otherwise use noon
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(targetDate, now);
    final initialDateTime = isToday
        ? now
        : DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            12,
            0,
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddWeightSheet(initialDate: initialDateTime),
    );
  }
}
