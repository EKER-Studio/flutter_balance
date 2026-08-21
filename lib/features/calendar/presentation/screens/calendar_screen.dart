// The calendar tab: a paged monthly grid paired with a selected-day details section.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_error_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_shimmer_skeleton.dart';
import 'package:balance/features/calendar/presentation/widgets/sections/calendar_month_card.dart';
import 'package:balance/features/calendar/presentation/widgets/sections/calendar_selected_day_section.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A screen showing weight measurements in a monthly calendar view.
///
/// Months are paged horizontally. Selecting a day filters the loaded entries
/// to that date, and a detail section shows either the day's measurements or
/// an empty state. Portrait layouts stack the sections vertically; landscape
/// layouts place the calendar card and detail section side by side.
/// Serves as the second tab in the main navigation.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// Tracks the focused month, the selected day, and month paging state for [CalendarScreen].
class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<AppSettingsBloc>().state.isHealthSyncEnabled) {
        context.read<WeightBloc>().add(const SyncHealthEntries());
      }
    });
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
  }

  /// Shifts the focused month one month back.
  void _previousMonth() {
    final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    AppAnalytics.logCalendarMonthChanged(
      '${newMonth.year}-${newMonth.month.toString().padLeft(2, '0')}',
    );
    setState(() {
      _focusedMonth = newMonth;
    });
  }

  /// Shifts the focused month one month forward.
  void _nextMonth() {
    final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    AppAnalytics.logCalendarMonthChanged(
      '${newMonth.year}-${newMonth.month.toString().padLeft(2, '0')}',
    );
    setState(() {
      _focusedMonth = newMonth;
    });
  }

  /// Selects the given [date].
  ///
  /// Moves the focused month if the selected date falls outside the current view.
  void _onDaySelected(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    final weightState = context.read<WeightBloc>().state;
    final entries = weightState is WeightLoaded
        ? weightState.entries
        : (weightState is WeightError ? weightState.entries : <WeightEntry>[]);
    final hasEntry = entries.any(
      (e) =>
          e.dateTime.year == date.year &&
          e.dateTime.month == date.month &&
          e.dateTime.day == date.day,
    );
    AppAnalytics.logCalendarDaySelected(date: dateStr, hasEntry: hasEntry);
    setState(() {
      _selectedDate = date;
      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appSettingsState = context.watch<AppSettingsBloc>().state;
    final targetWeight = appSettingsState.targetWeight;
    final unit = appSettingsState.measurementUnit;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          AppAnalytics.logCalendarPullToRefresh();
          if (context.read<AppSettingsBloc>().state.isHealthSyncEnabled) {
            context.read<WeightBloc>().add(const SyncHealthEntries());
            await Future.delayed(const Duration(seconds: 1));
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppTopBar(title: l10n.tabCalendar),
            SliverSafeArea(
              top: false,
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<WeightBloc, WeightState>(
                  builder: (context, state) {
                    final isLandscape =
                        MediaQuery.of(context).orientation ==
                        Orientation.landscape;
                    final maxContentWidth = isLandscape ? 900.0 : 600.0;
                    final horizontalPadding = 16.0;

                    if (state is WeightInitial || state is WeightLoading) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            child: const CalendarShimmerSkeleton(),
                          ),
                        ),
                      );
                    }

                    if (state is WeightError) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            child: CalendarErrorCard(
                              errorMessage: state.errorType.localizedMessage(
                                l10n,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final entries = state.entries;

                    final dayEntries = entries
                        .where(
                          (e) => DateUtils.isSameDay(e.dateTime, _selectedDate),
                        )
                        .toList();

                    final calendarCard = CalendarMonthCard(
                      focusedMonth: _focusedMonth,
                      selectedDate: _selectedDate,
                      entries: entries,
                      targetWeight: targetWeight,
                      onPreviousMonth: _previousMonth,
                      onNextMonth: _nextMonth,
                      onDaySelected: _onDaySelected,
                    );

                    final detailSection = CalendarSelectedDaySection(
                      selectedDate: _selectedDate,
                      dayEntries: dayEntries,
                      targetWeight: targetWeight,
                      unit: unit,
                    );

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 12,
                          ),
                          child: isLandscape
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: calendarCard),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 5, child: detailSection),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    calendarCard,
                                    const SizedBox(height: 24),
                                    detailSection,
                                    const SizedBox(height: 80),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
