import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLayoutTokens', () {
    test('defines correct breakpoint constants', () {
      expect(AppLayoutTokens.tabletBreakpoint, 600.0);
      expect(AppLayoutTokens.multiColumnBreakpoint, 720.0);
      expect(AppLayoutTokens.compactContentMaxWidth, 480.0);
      expect(AppLayoutTokens.maxSingleColumnContentWidth, 520.0);
      expect(AppLayoutTokens.expandedContentMaxWidth, 1200.0);
    });
  });

  group('ContextLayout extension', () {
    testWidgets('reports phone layout values when shortestSide < 600', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isTablet;
      late bool isMultiColumn;
      late double padding;
      late double maxWidth;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isTablet = context.isTablet;
              isMultiColumn = context.isMultiColumn;
              padding = context.contentHorizontalPadding;
              maxWidth = context.standardContentMaxWidth;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(isTablet, isFalse);
      expect(isMultiColumn, isFalse);
      expect(padding, 16.0);
      expect(maxWidth, 480.0);
    });

    testWidgets(
      'reports tablet portrait layout values when shortestSide >= 600 and width < 720',
      (tester) async {
        tester.view.physicalSize = const Size(600, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late bool isTablet;
        late bool isMultiColumn;
        late double padding;
        late double maxWidth;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                isTablet = context.isTablet;
                isMultiColumn = context.isMultiColumn;
                padding = context.contentHorizontalPadding;
                maxWidth = context.standardContentMaxWidth;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isTablet, isTrue);
        expect(isMultiColumn, isFalse);
        expect(padding, 40.0);
        expect(maxWidth, 520.0);
      },
    );

    testWidgets(
      'reports tablet landscape layout values when shortestSide >= 600 and width >= 720',
      (tester) async {
        tester.view.physicalSize = const Size(960, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late bool isTablet;
        late bool isMultiColumn;
        late double padding;
        late double maxWidth;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                isTablet = context.isTablet;
                isMultiColumn = context.isMultiColumn;
                padding = context.contentHorizontalPadding;
                maxWidth = context.standardContentMaxWidth;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(isTablet, isTrue);
        expect(isMultiColumn, isTrue);
        expect(padding, 24.0);
        expect(maxWidth, 1200.0);
      },
    );
  });
}
