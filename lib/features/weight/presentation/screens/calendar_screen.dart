import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_empty_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_entries_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_future_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_grid.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_month_header.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_weekday_header.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
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
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
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

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Focus month if selected date is in a different month
      if (date.year != _focusedMonth.year || date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final formattedSelectedDate = DateFormat.MMMMd(locale).format(_selectedDate);
    final targetWeight = context.watch<AppSettingsBloc>().state.targetWeight;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final isSelectedDateFuture = _selectedDate.isAfter(todayEnd);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.tabCalendar,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<WeightBloc, WeightState>(
          builder: (context, state) {
            final entries = switch (state) {
              WeightLoaded(:final entries) => entries,
              WeightError(:final entries) => entries,
              _ => <WeightEntry>[],
            };

            // Filter entries for the selected day
            final dayEntries = entries
                .where((e) => DateUtils.isSameDay(e.dateTime, _selectedDate))
                .toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            return ClampedLayout(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Calendar Card
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CalendarMonthHeader(
                              focusedMonth: _focusedMonth,
                              onPreviousMonth: _previousMonth,
                              onNextMonth: _nextMonth,
                            ),
                            const SizedBox(height: 16),
                            const CalendarWeekdayHeader(),
                            const SizedBox(height: 12),
                            CalendarGrid(
                              focusedMonth: _focusedMonth,
                              selectedDate: _selectedDate,
                              entries: entries,
                              targetWeight: targetWeight,
                              onDaySelected: (date, _) => _onDaySelected(date),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Selected Day Header
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        'Zapisy z $formattedSelectedDate',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ),
                    // Selected Day Details / Future / Empty State Card
                    if (isSelectedDateFuture)
                      CalendarDayFutureCard(
                        selectedDate: _selectedDate,
                        onSelectToday: () => _onDaySelected(DateTime.now()),
                      )
                    else if (dayEntries.isEmpty)
                      CalendarDayEmptyCard(selectedDate: _selectedDate)
                    else
                      CalendarDayEntriesCard(
                        selectedDate: _selectedDate,
                        entries: dayEntries,
                        targetWeight: targetWeight,
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeightSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddWeightSheet(),
    );
  }
}
