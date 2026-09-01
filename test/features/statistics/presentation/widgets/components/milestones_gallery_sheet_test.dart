import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestone_badge.dart';
import 'package:balance/features/statistics/presentation/widgets/components/milestones_gallery_sheet.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildSubject(List<Milestone> milestones) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: MilestonesGallerySheet(milestones: milestones)),
    );
  }

  group('MilestonesGallerySheet', () {
    testWidgets('renders all categories and milestone badges', (tester) async {
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
        Milestone(
          type: MilestoneType.earlyBird,
          isUnlocked: true,
          progress: 1.0,
        ),
        Milestone(
          type: MilestoneType.newYear,
          isUnlocked: false,
          progress: 0.0,
        ),
      ];

      await tester.pumpWidget(buildSubject(milestones));
      await tester.pumpAndSettle();

      expect(find.text('Achievements Gallery'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Goals & Progress'), findsOneWidget);
      expect(find.text('Consistency & Habits'), findsOneWidget);
      expect(find.text('Routines & Time'), findsOneWidget);
      expect(
        find.text('Special Occasions', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(MilestoneBadge, skipOffstage: false), findsNWidgets(4));
    });
  });
}
