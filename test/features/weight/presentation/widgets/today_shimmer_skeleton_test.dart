import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/features/weight/presentation/widgets/today_shimmer_skeleton.dart';

void main() {
  testWidgets('TodayShimmerSkeleton renders placeholder cards and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TodayShimmerSkeleton(),
        ),
      ),
    );

    expect(find.byType(TodayShimmerSkeleton), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));

    // Advance animation clock
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TodayShimmerSkeleton), findsOneWidget);
  });
}
