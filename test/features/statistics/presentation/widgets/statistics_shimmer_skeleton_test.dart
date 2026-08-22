import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/statistics/presentation/widgets/sections/statistics_shimmer_skeleton.dart';

void main() {
  testWidgets('renders skeleton cards mirroring the statistics layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatisticsShimmerSkeleton())),
    );

    expect(find.byType(StatisticsShimmerSkeleton), findsOneWidget);

    // 2 habit summary cards + 1 hero trend card + 4 bento grid cards.
    expect(find.byType(Card), findsNWidgets(7));
    expect(find.byType(Row), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('animates the shimmer value over time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatisticsShimmerSkeleton())),
    );

    final animatedBuilders = find.descendant(
      of: find.byType(StatisticsShimmerSkeleton),
      matching: find.byType(AnimatedBuilder),
    );
    final animatedBuilder = tester
        .widgetList<AnimatedBuilder>(animatedBuilders)
        .first;
    final animation = animatedBuilder.animation as Animation<double>;
    final valueBefore = animation.value;

    await tester.pump(const Duration(milliseconds: 500));

    expect(animation.value, isNot(valueBefore));
    expect(animation.value, inInclusiveRange(0.35, 0.85));
  });

  testWidgets('repeats the animation in reverse over the full cycle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatisticsShimmerSkeleton())),
    );

    final animatedBuilders = find.descendant(
      of: find.byType(StatisticsShimmerSkeleton),
      matching: find.byType(AnimatedBuilder),
    );
    final animatedBuilder = tester
        .widgetList<AnimatedBuilder>(animatedBuilders)
        .first;
    final animation = animatedBuilder.animation as Animation<double>;

    await tester.pump(const Duration(milliseconds: 1000));
    final nearEnd = animation.value;

    await tester.pump(const Duration(milliseconds: 1000));
    final backToStart = animation.value;

    expect(nearEnd, isNot(backToStart));
    expect(animation.isAnimating, isTrue);
  });

  testWidgets('disposes cleanly without pending timers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatisticsShimmerSkeleton())),
    );
    await tester.pumpWidget(const SizedBox());

    expect(find.byType(StatisticsShimmerSkeleton), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
