import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/features/weight/presentation/widgets/add_weight_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_day_detail_sheet.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_grid.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_month_header.dart';
import 'package:pure_weight/features/weight/presentation/widgets/calendar/calendar_weekday_header.dart';
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

            return ClampedLayout(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CalendarMonthHeader(
                    focusedMonth: _focusedMonth,
                    onPreviousMonth: _previousMonth,
                    onNextMonth: _nextMonth,
                  ),
                  const SizedBox(height: 16),
                  const CalendarWeekdayHeader(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CalendarGrid(
                      focusedMonth: _focusedMonth,
                      entries: entries,
                      onDaySelected: (date, dayEntries) {
                        CalendarDayDetailSheet.show(
                          context,
                          date: date,
                          entries: dayEntries,
                        );
                      },
                    ),
                  ),
                ],
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
