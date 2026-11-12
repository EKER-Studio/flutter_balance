import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/analytics/analytics_service.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/hero_progress_card.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockAnalyticsService analytics;

  setUp(() {
    analytics = MockAnalyticsService();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    AppAnalytics.setService(analytics);
  });

  /// Pumps [child] inside a [MaterialApp] with the app's localization delegates
  /// and a [Scaffold] (the [HeroProgressCard] uses an [InkWell], which requires
  /// a [Material] ancestor).
  Future<void> pumpWithL10n(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Builds [entries] newest-first so the card's ascending sort yields the
  /// expected [firstKg] (oldest) and [latestKg] (newest) measurements.
  List<WeightEntry> entries(double firstKg, double latestKg) => [
    WeightEntry(weightKg: latestKg, dateTime: DateTime(2024, 6, 1)),
    WeightEntry(weightKg: firstKg, dateTime: DateTime(2024, 1, 1)),
  ];

  group('HeroProgressCard — gain mode', () {
    testWidgets(
      'shows "Goal achieved!" when latest weight is at or above target',
      (tester) async {
        await pumpWithL10n(
          tester,
          HeroProgressCard(
            entries: entries(70.0, 80.0),
            targetWeight: 75.0,
            weeklyPace: null,
            unit: MeasurementUnit.metric,
            goalMode: WeightGoalMode.gain,
          ),
        );

        expect(find.text('Goal achieved!'), findsOneWidget);
        expect(find.text('Goal progress'), findsOneWidget);
      },
    );

    testWidgets('shows remaining distance to target when below target', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 72.0),
          targetWeight: 80.0,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.gain,
        ),
      );

      expect(find.text('8.0 kg to target'), findsOneWidget);
      expect(find.text('Goal progress'), findsOneWidget);
    });

    testWidgets('converts the remaining distance to imperial units', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 72.0),
          targetWeight: 80.0,
          weeklyPace: null,
          unit: MeasurementUnit.imperial,
          goalMode: WeightGoalMode.gain,
        ),
      );

      // 8.0 kg remaining is converted to pounds (≈ 17.6 lb).
      expect(find.textContaining('lb to target'), findsOneWidget);
    });
  });

  group('HeroProgressCard — maintain mode', () {
    testWidgets('shows "Weight stable" when within the maintenance threshold', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 71.0),
          targetWeight: 70.0,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.maintain,
        ),
      );

      expect(find.textContaining('Weight stable'), findsOneWidget);
      expect(find.text('Goal progress'), findsOneWidget);
    });

    testWidgets('shows the deviation badge when outside the threshold', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 73.0),
          targetWeight: 70.0,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.maintain,
        ),
      );

      expect(find.textContaining('Deviation:'), findsOneWidget);
      expect(find.text('Goal progress'), findsOneWidget);
    });

    testWidgets('converts the deviation distance to imperial units', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 73.0),
          targetWeight: 70.0,
          weeklyPace: null,
          unit: MeasurementUnit.imperial,
          goalMode: WeightGoalMode.maintain,
        ),
      );

      // 3.0 kg deviation is converted to pounds (≈ 6.6 lb).
      expect(find.textContaining('Deviation:'), findsOneWidget);
    });
  });

  group('HeroProgressCard — no target (great job)', () {
    testWidgets('shows "Great job!" for a gain trend', (tester) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 75.0),
          targetWeight: null,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.gain,
        ),
      );

      expect(find.text('Great job!'), findsOneWidget);
    });

    testWidgets('shows "Great job!" for a lose trend', (tester) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 65.0),
          targetWeight: null,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.lose,
        ),
      );

      expect(find.text('Great job!'), findsOneWidget);
    });

    testWidgets('shows "Great job!" for a stable maintain trend', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 70.5),
          targetWeight: null,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.maintain,
        ),
      );

      expect(find.text('Great job!'), findsOneWidget);
    });
  });

  group('HeroProgressCard — interactions', () {
    testWidgets('logs an analytics event when the card is tapped', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 75.0),
          targetWeight: 72.0,
          weeklyPace: null,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.lose,
        ),
      );

      await tester.tap(find.text('Total Progress'));
      await tester.pump();

      verify(
        () => analytics.logEvent(
          name: 'statistics_hero_progress_card_tapped',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });

    testWidgets('renders the pace-window edit icon and fires its tap', (
      tester,
    ) async {
      var paceTapped = false;
      await pumpWithL10n(
        tester,
        HeroProgressCard(
          entries: entries(70.0, 75.0),
          targetWeight: 72.0,
          weeklyPace: 1.0,
          unit: MeasurementUnit.metric,
          goalMode: WeightGoalMode.lose,
          onPaceWindowTap: () => paceTapped = true,
        ),
      );

      // The edit icon only renders when onPaceWindowTap is provided.
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.textContaining('1.0 kg/week'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(paceTapped, isTrue);
    });
  });
}
