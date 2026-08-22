import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/widgets/custom_settings_tile.dart';

void main() {
  group('CustomSettingsTile', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(title: 'Test Title', icon: Icons.settings),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders subtitle and valueText', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              subtitle: 'Test Subtitle',
              valueText: 'Test Value',
            ),
          ),
        ),
      );

      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Value'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('has correct semantics label with section label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              sectionLabel: 'Section',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CustomSettingsTile));
      expect(semantics.label, 'Section, Test Title, Subtitle');
    });
    testWidgets('shows error styling when isError is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              subtitle: 'Subtitle',
              valueText: 'Value',
              isError: true,
            ),
          ),
        ),
      );

      final errorColor = Theme.of(
        tester.element(find.text('Test Title')),
      ).colorScheme.error;
      expect(
        tester.widget<Text>(find.text('Test Title')).style?.color,
        errorColor,
      );
      expect(tester.widget<Text>(find.text('Value')).style?.color, errorColor);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.settings)).color,
        errorColor,
      );
    });

    testWidgets('does not show a chevron when showChevron is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              showChevron: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows a chevron before valueText when chevron is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              valueText: 'Value',
              showChevron: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('draws a focus border when the tile receives focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSettingsTile(
              title: 'Test Title',
              icon: Icons.settings,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final focusNode = tester
          .widgetList<Focus>(find.byType(Focus))
          .map((f) => f.focusNode)
          .whereType<FocusNode>()
          .firstWhere((node) => !node.hasFocus);
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      final boxes = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((c) => c.decoration is BoxDecoration)
          .where(
            (c) =>
                (c.decoration as BoxDecoration).border is Border &&
                ((c.decoration as BoxDecoration).border! as Border)
                        .top
                        .width ==
                    2,
          );
      expect(boxes, isNotEmpty);
    });
  });
}
