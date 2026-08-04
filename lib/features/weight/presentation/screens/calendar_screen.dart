import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_empty_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_entries_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_future_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_error_card.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_grid.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_month_header.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_shimmer_skeleton.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_weekday_header.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/core/clamped_layout.dart';
import 'package:pure_weight/presentation/widgets/app_top_bar.dart';

/// Tab 2: Calendar Screen providing a monthly view with measurement status indicators.
class CalendarScreen extends StatefulWidget {
  /// Creates [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// Tracks the focused month and selected day for the calendar grid.
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

  /// Shifts the focused month one month back.
  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  /// Shifts the focused month one month forward.
  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  /// Selects [date], moving the focused month if it falls outside it.
  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Focus month if selected date is in a different month
      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final formattedSelectedDate = DateFormat.MMMMd(
      locale,
    ).format(_selectedDate);
    final targetWeight = context.watch<AppSettingsBloc>().state.targetWeight;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final isSelectedDateFuture = _selectedDate.isAfter(todayEnd);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppTopBar(title: l10n.tabCalendar),
          SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<WeightBloc, WeightState>(
                builder: (context, state) {
                  if (state is WeightInitial || state is WeightLoading) {
                    return const ClampedLayout(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: CalendarShimmerSkeleton(),
                    );
                  }

                  if (state is WeightError) {
                    return ClampedLayout(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: CalendarErrorCard(
                        errorMessage: state.errorType.localizedMessage(l10n),
                      ),
                    );
                  }

                  final entries = switch (state) {
                    WeightLoaded(:final entries) => entries,
                    _ => <WeightEntry>[],
                  };

                  // Filter entries for the selected day
                  final dayEntries = entries
                      .where(
                        (e) => DateUtils.isSameDay(e.dateTime, _selectedDate),
                      )
                      .toList();

                  return ClampedLayout(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Calendar Card
                        Card(
                          elevation: 0,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
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
                                  onDaySelected: (date, _) =>
                                      _onDaySelected(date),
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
                            l10n.entriesFromDate(formattedSelectedDate),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
