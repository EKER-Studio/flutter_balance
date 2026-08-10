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
  });
}
