import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/core/presentation/theme/app_chart_theme.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  /// Pumps a [MaterialApp] with the app's localization delegates and captures a
  /// live [BuildContext] plus the resolved [AppLocalizations] for the current
  /// [locale], so the context-dependent static helpers can be exercised.
  late BuildContext capturedContext;
  late AppLocalizations capturedL10n;

  Future<void> pumpContext(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    // The localization delegate loads asynchronously; resolve it only after the
    // tree has settled so `AppLocalizations.of` returns a loaded instance.
    await tester.pumpAndSettle();
    capturedL10n = AppLocalizations.of(capturedContext);
  }

  group('AppChartTheme — static builders', () {
    test('gridData returns a visible horizontal grid with dashed lines', () {
      final data = AppChartTheme.gridData(
        colorScheme: AppTheme.lightColorScheme,
        horizontalInterval: 2,
      );

      expect(data.show, isTrue);
      expect(data.drawVerticalLine, isFalse);
      expect(data.horizontalInterval, 2);
      expect(data.getDrawingHorizontalLine(0), isA<FlLine>());
    });

    test('borderData returns a hidden border', () {
      expect(AppChartTheme.borderData().show, isFalse);
    });

    test('lineGradient returns a two-stop gradient', () {
      final gradient = AppChartTheme.lineGradient(Colors.blue);
      expect(gradient.colors, hasLength(2));
    });

    test('belowBarGradient is a top-to-bottom two-stop gradient', () {
      final gradient = AppChartTheme.belowBarGradient(Colors.blue);
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors, hasLength(2));
    });
  });

  group('AppChartTheme — bottomInterval', () {
    test('returns 1 for a length of 1 or less', () {
      expect(AppChartTheme.bottomInterval(0, TimePeriod.week), 1.0);
      expect(AppChartTheme.bottomInterval(1, TimePeriod.week), 1.0);
    });

    test('uses 6 target intervals for week', () {
      // (7 - 1) / 6 = 1.0 → ceil = 1
      expect(AppChartTheme.bottomInterval(7, TimePeriod.week), 1.0);
    });

    test('uses 4 target intervals for month', () {
      // (30 - 1) / 4 = 7.25 → ceil = 8
      expect(AppChartTheme.bottomInterval(30, TimePeriod.month), 8.0);
    });

    test('uses 5 target intervals for year', () {
      // (365 - 1) / 5 = 72.8 → ceil = 73
      expect(AppChartTheme.bottomInterval(365, TimePeriod.year), 73.0);
    });

    test('uses 5 target intervals for all', () {
      // (100 - 1) / 5 = 19.8 → ceil = 20
      expect(AppChartTheme.bottomInterval(100, TimePeriod.all), 20.0);
    });
  });

  group('AppChartTheme — weekdayLabel', () {
    testWidgets('maps every weekday to its localized short name', (
      tester,
    ) async {
      await pumpContext(tester);

      expect(AppChartTheme.weekdayLabel(DateTime.monday, capturedL10n), 'Mon');
      expect(AppChartTheme.weekdayLabel(DateTime.tuesday, capturedL10n), 'Tue');
      expect(
        AppChartTheme.weekdayLabel(DateTime.wednesday, capturedL10n),
        'Wed',
      );
      expect(
        AppChartTheme.weekdayLabel(DateTime.thursday, capturedL10n),
        'Thu',
      );
      expect(AppChartTheme.weekdayLabel(DateTime.friday, capturedL10n), 'Fri');
      expect(
        AppChartTheme.weekdayLabel(DateTime.saturday, capturedL10n),
        'Sat',
      );
      expect(AppChartTheme.weekdayLabel(DateTime.sunday, capturedL10n), 'Sun');
    });

    testWidgets('falls back to Monday for out-of-range weekday values', (
      tester,
    ) async {
      await pumpContext(tester);

      expect(AppChartTheme.weekdayLabel(0, capturedL10n), 'Mon');
      expect(AppChartTheme.weekdayLabel(8, capturedL10n), 'Mon');
    });
  });

  group('AppChartTheme — bottomAxisLabel', () {
    testWidgets('renders a weekday label for the week period', (tester) async {
      await pumpContext(tester);

      // 2024-01-15 is a Monday.
      final label = AppChartTheme.bottomAxisLabel(
        capturedContext,
        DateTime(2024, 1, 15),
        TimePeriod.week,
        capturedL10n,
      );

      expect(label, 'Mon');
    });

    testWidgets('renders the day-of-month for the month period', (
      tester,
    ) async {
      await pumpContext(tester);

      final label = AppChartTheme.bottomAxisLabel(
        capturedContext,
        DateTime(2024, 3, 15),
        TimePeriod.month,
        capturedL10n,
      );

      expect(label, '15');
    });

    testWidgets('renders a month label for the year period', (tester) async {
      await pumpContext(tester);

      final label = AppChartTheme.bottomAxisLabel(
        capturedContext,
        DateTime(2024, 3, 15),
        TimePeriod.year,
        capturedL10n,
      );

      expect(label, 'Mar');
    });

    testWidgets('renders a month label for the all period', (tester) async {
      await pumpContext(tester);

      final label = AppChartTheme.bottomAxisLabel(
        capturedContext,
        DateTime(2024, 12, 15),
        TimePeriod.all,
        capturedL10n,
      );

      expect(label, 'Dec');
    });
  });

  group('AppChartTheme — monthLabel', () {
    testWidgets('formats a date into its localized short month name', (
      tester,
    ) async {
      await pumpContext(tester);

      expect(
        AppChartTheme.monthLabel(capturedContext, DateTime(2024, 1, 15)),
        'Jan',
      );
      expect(
        AppChartTheme.monthLabel(capturedContext, DateTime(2024, 6, 15)),
        'Jun',
      );
      expect(
        AppChartTheme.monthLabel(capturedContext, DateTime(2024, 12, 15)),
        'Dec',
      );
    });
  });

  group('AppChartTheme — isDuplicateMonthTick', () {
    test('returns false for non year/all periods', () {
      final dates = [DateTime(2024, 1, 15), DateTime(2024, 1, 20)];

      expect(
        AppChartTheme.isDuplicateMonthTick(1, dates, TimePeriod.week),
        isFalse,
      );
      expect(
        AppChartTheme.isDuplicateMonthTick(1, dates, TimePeriod.month),
        isFalse,
      );
    });

    test('returns false for out-of-range indices', () {
      final dates = [DateTime(2024, 1, 15), DateTime(2024, 1, 20)];

      expect(
        AppChartTheme.isDuplicateMonthTick(0, dates, TimePeriod.year),
        isFalse,
      );
      expect(
        AppChartTheme.isDuplicateMonthTick(5, dates, TimePeriod.year),
        isFalse,
      );
      expect(
        AppChartTheme.isDuplicateMonthTick(0, dates, TimePeriod.all),
        isFalse,
      );
    });

    test('returns true when the tick shares the previous month', () {
      final dates = [DateTime(2024, 1, 15), DateTime(2024, 1, 20)];

      expect(
        AppChartTheme.isDuplicateMonthTick(1, dates, TimePeriod.year),
        isTrue,
      );
      expect(
        AppChartTheme.isDuplicateMonthTick(1, dates, TimePeriod.all),
        isTrue,
      );
    });

    test('returns false when the tick crosses into a new month', () {
      final dates = [DateTime(2024, 1, 15), DateTime(2024, 2, 20)];

      expect(
        AppChartTheme.isDuplicateMonthTick(1, dates, TimePeriod.year),
        isFalse,
      );
    });
  });
}
