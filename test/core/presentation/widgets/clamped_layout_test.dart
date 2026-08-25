import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';

void main() {
  Widget buildLayout({EdgeInsetsGeometry? padding, Widget? child}) {
    return MaterialApp(
      home: Scaffold(
        body: ClampedLayout(
          padding: padding,
          child: child ?? const SizedBox(width: 40, height: 40),
        ),
      ),
    );
  }

  testWidgets('centers the child in a 600px-wide clamped area', (tester) async {
    await tester.pumpWidget(
      buildLayout(child: const SizedBox(width: 1000, height: 40)),
    );

    final constrained = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrained.constraints.maxWidth, 600);

    final align = tester.widget<Align>(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(Align),
      ),
    );
    expect(align.alignment, Alignment.topCenter);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('renders the child without padding when padding is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildLayout(child: const SizedBox(width: 1000, height: 40)),
    );
    expect(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(Padding),
      ),
      findsNothing,
    );
  });

  testWidgets('wraps the child in padding when padding is provided', (
    tester,
  ) async {
    const padding = EdgeInsets.all(16);
    await tester.pumpWidget(buildLayout(padding: padding));

    final paddingWidget = tester.widget<Padding>(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(Padding),
      ),
    );
    expect(paddingWidget.padding, padding);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('clamps width to 600 even in a wider parent', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildLayout(child: const SizedBox(width: 1000, height: 40)),
    );

    final constrained = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrained.constraints.maxWidth, 600);

    final box = tester.getSize(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(box.width, 600);
  });

  testWidgets('fits content width when the parent is narrower than 600', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildLayout(child: const SizedBox(width: 1000, height: 40)),
    );

    final box = tester.getSize(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(box.width, 400);
  });

  testWidgets('clamps width to custom maxWidth when specified', (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClampedLayout(
            maxWidth: 1000,
            child: SizedBox(width: 1200, height: 40),
          ),
        ),
      ),
    );

    final constrained = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(ClampedLayout),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrained.constraints.maxWidth, 1000);
  });
}
