import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/unit_converter.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_empty_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_entries_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_day_future_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_error_card.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_month_header.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_shimmer_skeleton.dart';
import 'package:balance/features/calendar/presentation/widgets/calendar_weekday_header.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/presentation/widgets/app_top_bar.dart';
import 'package:balance/presentation/core/clamped_layout.dart';

/// Tab 2: Calendar Screen providing a monthly view with measurement status indicators.
class CalendarScreen extends StatefulWidget {
  /// Creates [CalendarScreen].
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// State tracking the focused month and selected day for the calendar grid.
class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late PageController _pageController;
  final int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Updates [_focusedMonth] to match the page now centered in the view.
  void _onPageChanged(int index) {
    final offset = index - _initialPage;
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month + offset, 1);
    });
  }

  /// Shifts the focused month one month back.
  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Shifts the focused month one month forward.
  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Selects [date], moving the focused month if it falls outside it.
  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Focus month if selected date is in a different month
      if (date.year != _focusedMonth.year ||
          date.month != _focusedMonth.month) {
        final now = DateTime.now();
        final monthsDiff =
            (date.year - now.year) * 12 + (date.month - now.month);
        final targetPage = _initialPage + monthsDiff;

        _focusedMonth = DateTime(date.year, date.month, 1);
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isLandscape =
                            MediaQuery.of(context).orientation ==
                            Orientation.landscape;
                        final calendarCard = Card(
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
                                Builder(
                                  builder: (context) {
                                    final availableWidth =
                                        isLandscape &&
                                            constraints.maxWidth >= 720
                                        ? (constraints.maxWidth - 116) / 2
                                        : constraints.maxWidth - 64;
                                    final cellWidth = (availableWidth - 24) / 7;
                                    // 6 rows, 5 main-axis spacings of 8, plus a small buffer.
                                    final gridHeight = (6 * cellWidth) + 40 + 2;

                                    return SizedBox(
                                      height: gridHeight,
                                      child: PageView.builder(
                                        controller: _pageController,
                                        clipBehavior: Clip.none,
                                        allowImplicitScrolling: true,
                                        onPageChanged: _onPageChanged,
                                        itemBuilder: (context, index) {
                                          final offset = index - _initialPage;
                                          final now = DateTime.now();
                                          final monthDate = DateTime(
                                            now.year,
                                            now.month + offset,
                                            1,
                                          );

                                          return CalendarGrid(
                                            focusedMonth: monthDate,
                                            selectedDate: _selectedDate,
                                            entries: entries,
                                            targetWeight: targetWeight,
                                            onDaySelected: (date, _) =>
                                                _onDaySelected(date),
                                          );
                                        },
                                      ),
                                    );
                                  },
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
                          padding: const EdgeInsets.only(bottom: 16),
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
                            if (isSelectedDateFuture)
                              CalendarDayFutureCard(
                                selectedDate: _selectedDate,
                                onSelectToday: () =>
                                    _onDaySelected(DateTime.now()),
                              )
                            else if (dayEntries.isEmpty)
                              CalendarDayEmptyCard(selectedDate: _selectedDate)
                            else
                              CalendarDayEntriesCard(
                                selectedDate: _selectedDate,
                                entries: dayEntries,
                                targetWeight: targetWeight,
                              ),
                          ],
                        );

                        if (isLandscape && constraints.maxWidth >= 720) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: calendarCard),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: detailSection),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calendarCard,
                            const SizedBox(height: 24),
                            detailSection,
                            const SizedBox(height: 80),
                          ],
                        );
                      },
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
