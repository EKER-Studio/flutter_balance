import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestone_badge.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/milestones_card.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildSubject(List<Milestone> milestones) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MilestonesCard(milestones: milestones),
        ),
      ),
    );
  }

  group('MilestonesCard', () {
    testWidgets('renders milestone header, unlock counter, and badges', (
      tester,
    ) async {
      const milestones = [
        Milestone(
          type: MilestoneType.firstEntry,
          isUnlocked: true,
          progress: 1.0,
        ),
        Milestone(
          type: MilestoneType.streak7,
          isUnlocked: false,
          progress: 0.5,
        ),
      ];

      await tester.pumpWidget(buildSubject(milestones));
      await tester.pumpAndSettle();

      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('7-Day Streak'), findsOneWidget);
      expect(find.byType(MilestoneBadge), findsNWidgets(2));
    });

    testWidgets('tapping milestone badge opens detail dialog', (tester) async {
      final milestones = [
        Milestone(
          type: MilestoneType.firstEntry,
          isUnlocked: true,
          progress: 1.0,
          unlockedDate: DateTime(2026, 8, 1),
        ),
      ];

      await tester.pumpWidget(buildSubject(milestones));
      await tester.pumpAndSettle();

      await tester.tap(find.text('First Step'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Logged your first weight entry'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping milestones card opens milestones gallery sheet', (
      tester,
    ) async {
      const milestones = [
        Milestone(
          type: MilestoneType.firstEntry,
          isUnlocked: true,
          progress: 1.0,
        ),
      ];

      await tester.pumpWidget(buildSubject(milestones));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      expect(find.text('Achievements Gallery'), findsOneWidget);
    });

    testWidgets(
      'tapping milestone badge opens detail dialog without overflow on low-height landscape',
      (tester) async {
        // Small landscape phone viewport: 800x320
        tester.view.physicalSize = const Size(800, 320);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final milestones = [
          Milestone(
            type: MilestoneType.streak30,
            isUnlocked: true,
            progress: 1.0,
            unlockedDate: DateTime(2026, 6, 28),
          ),
          const Milestone(
            type: MilestoneType.streak100,
            isUnlocked: false,
            progress: 0.95,
          ),
        ];

        await tester.pumpWidget(buildSubject(milestones));
        await tester.pumpAndSettle();

        await tester.tap(find.text('30-Day Habit'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('30-Day Habit'), findsWidgets);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });
}
