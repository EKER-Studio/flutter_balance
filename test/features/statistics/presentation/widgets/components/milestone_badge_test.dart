import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/analytics/analytics_service.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestone_badge.dart';
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
  /// and a [Scaffold] (the [MilestoneBadge] uses an [InkWell], which requires a
  /// [Material] ancestor).
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

  group('MilestoneBadge — locked milestone detail dialog', () {
    testWidgets('shows the progress bar and percentage when locked', (
      tester,
    ) async {
      const milestone = Milestone(
        type: MilestoneType.streak7,
        isUnlocked: false,
        progress: 0.5,
      );

      await pumpWithL10n(tester, const MilestoneBadge(milestone: milestone));

      // The badge itself renders (icon + title + progress strip).
      expect(find.byType(MilestoneBadge), findsOneWidget);

      // Tap the badge to open the detail dialog.
      await tester.tap(find.byType(MilestoneBadge));
      await tester.pumpAndSettle();

      // The locked-milestone dialog shows the progress bar and "50%" text.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      // The in-progress bar (FractionallySizedBox inside the dialog).
      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    testWidgets('rounds the progress percentage to an integer', (tester) async {
      const milestone = Milestone(
        type: MilestoneType.streak30,
        isUnlocked: false,
        progress: 0.333,
      );

      await pumpWithL10n(tester, const MilestoneBadge(milestone: milestone));

      await tester.tap(find.byType(MilestoneBadge));
      await tester.pumpAndSettle();

      // (0.333 * 100).toInt() == 33.
      expect(find.text('33%'), findsOneWidget);
    });

    testWidgets('logs the detail-tapped analytics event with locked flag', (
      tester,
    ) async {
      const milestone = Milestone(
        type: MilestoneType.streak7,
        isUnlocked: false,
        progress: 0.5,
      );

      await pumpWithL10n(tester, const MilestoneBadge(milestone: milestone));

      await tester.tap(find.byType(MilestoneBadge));
      await tester.pump();

      verify(
        () => analytics.logEvent(
          name: 'statistics_milestone_detail_tapped',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });
  });

  group('MilestoneBadge — unlocked milestone detail dialog', () {
    testWidgets('shows the unlocked date and success bar when unlocked', (
      tester,
    ) async {
      final milestone = Milestone(
        type: MilestoneType.streak7,
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: DateTime(2024, 6, 15),
      );

      await pumpWithL10n(tester, MilestoneBadge(milestone: milestone));

      await tester.tap(find.byType(MilestoneBadge));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // The unlocked date is rendered (locale-formatted, contains "June 15").
      expect(find.textContaining('June 15'), findsOneWidget);
    });

    testWidgets('logs the detail-tapped analytics event with unlocked flag', (
      tester,
    ) async {
      final milestone = Milestone(
        type: MilestoneType.streak7,
        isUnlocked: true,
        progress: 1.0,
        unlockedDate: DateTime(2024, 6, 15),
      );

      await pumpWithL10n(tester, MilestoneBadge(milestone: milestone));

      await tester.tap(find.byType(MilestoneBadge));
      await tester.pump();

      verify(
        () => analytics.logEvent(
          name: 'statistics_milestone_detail_tapped',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    });
  });
}
