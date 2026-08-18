// The calendar tab: a paged monthly grid paired with a selected-day details section.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_empty_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_entries_card.dart';

import 'package:balance/features/calendar/presentation/widgets/calendar_error_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_month_header.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_shimmer_skeleton.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_weekday_header.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/core/presentation/widgets/app_top_bar.dart';

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

  @override
  void dispose() {
    super.dispose();
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

  /// Selects the given [date].
  ///
  /// Moves the focused month if the selected date falls outside the current view.
  void _onDaySelected(DateTime date) {
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
    final locale = Localizations.localeOf(context).toString();
    final formattedSelectedDate = DateFormat.MMMMd(
      locale,
    ).format(_selectedDate);
    final appSettingsState = context.watch<AppSettingsBloc>().state;
    final targetWeight = appSettingsState.targetWeight;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
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

                    final entries = switch (state) {
                      WeightLoaded(:final entries) => entries,
                      _ => <WeightEntry>[],
                    };

                    final dayEntries = entries
                        .where(
                          (e) => DateUtils.isSameDay(e.dateTime, _selectedDate),
                        )
                        .toList();

                    final calendarCard = Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isLandscape ? 24 : 28,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          isLandscape ? 16 : 16,
                          0,
                          isLandscape ? 16 : 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: CalendarMonthHeader(
                                focusedMonth: _focusedMonth,
                                onPreviousMonth: _previousMonth,
                                onNextMonth: _nextMonth,
                              ),
                            ),
                            SizedBox(height: isLandscape ? 12 : 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: CalendarWeekdayHeader(),
                            ),
                            SizedBox(height: isLandscape ? 10 : 12),
                            GestureDetector(
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity != null) {
                                  if (details.primaryVelocity! > 0) {
                                    _previousMonth();
                                  } else if (details.primaryVelocity! < 0) {
                                    _nextMonth();
                                  }
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: CalendarGrid(
                                    key: ValueKey(_focusedMonth),
                                    focusedMonth: _focusedMonth,
                                    selectedDate: _selectedDate,
                                    entries: entries,
                                    targetWeight: targetWeight,
                                    onDaySelected: (date, _) =>
                                        _onDaySelected(date),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final isImperial =
                        appSettingsState.measurementUnit ==
                        MeasurementUnit.imperial;
                    final unitLabel = unitLabelFor(
                      appSettingsState.measurementUnit,
                    );
                    double averageKg = 0;
                    if (dayEntries.isNotEmpty) {
                      averageKg =
                          dayEntries.fold<double>(
                            0,
                            (sum, e) => sum + e.weightKg,
                          ) /
                          dayEntries.length;
                    }
                    final displayAverage = isImperial
                        ? kgToLbs(averageKg)
                        : averageKg;

                    final selectedDayHeader = Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.entriesFromDate(formattedSelectedDate),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (dayEntries.length > 1) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.multipleEntries(dayEntries.length)} • ${l10n.averageWeight}: ${displayAverage.toStringAsFixed(1)} $unitLabel',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    );

                    final detailSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        selectedDayHeader,
                        if (dayEntries.isEmpty)
                          CalendarDayEmptyCard(selectedDate: _selectedDate)
                        else
                          CalendarDayEntriesCard(
                            selectedDate: _selectedDate,
                            entries: dayEntries,
                            targetWeight: targetWeight,
                          ),
                      ],
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
