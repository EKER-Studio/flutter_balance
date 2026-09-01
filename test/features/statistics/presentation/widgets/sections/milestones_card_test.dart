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
  });
}
