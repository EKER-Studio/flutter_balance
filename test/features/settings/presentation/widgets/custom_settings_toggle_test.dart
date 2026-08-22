import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/widgets/custom_settings_toggle.dart';

void main() {
  Widget buildTestWidget({
    required bool value,
    ValueChanged<bool>? onChanged,
    String? subtitle,
    String? sectionLabel,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomSettingsToggle(
          icon: Icons.notifications_outlined,
          title: 'Daily Reminder',
          subtitle: subtitle,
          value: value,
          onChanged: onChanged,
          sectionLabel: sectionLabel,
        ),
      ),
    );
  }

  group('CustomSettingsToggle', () {
    testWidgets('renders title, subtitle, and icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(value: false, subtitle: 'Reminder description'),
      );

      expect(find.text('Daily Reminder'), findsOneWidget);
      expect(find.text('Reminder description'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders without subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false));

      expect(find.text('Daily Reminder'), findsOneWidget);
    });

    testWidgets('switch reflects the provided value', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: true));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggling calls onChanged with the new value', (tester) async {
      bool? received;
      await tester.pumpWidget(
        buildTestWidget(value: false, onChanged: (v) => received = v),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(received, isTrue);
    });

    testWidgets('switch is disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: false, onChanged: null));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('exposes toggled semantics matching the value', (tester) async {
      await tester.pumpWidget(buildTestWidget(value: true));

      final semantics = tester
          .getSemantics(find.bySemanticsLabel('Daily Reminder').first)
          .getSemanticsData();
      expect(semantics.flagsCollection.isToggled, Tristate.isTrue);
    });

    testWidgets('prefixes section label into the semantics label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(value: false, sectionLabel: 'Application'),
      );

      expect(
        find.bySemanticsLabel('Application, Daily Reminder'),
        findsOneWidget,
      );
    });

    testWidgets('shows a focus ring while focused and removes it on blur', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(value: false));

      final borderContainer = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null,
      );
      expect(borderContainer, findsNothing);

      final focusNode = tester
          .widget<Focus>(
            find
                .descendant(
                  of: find.byType(CustomSettingsToggle),
                  matching: find.byType(Focus),
                )
                .first,
          )
          .focusNode!;
      focusNode.requestFocus();
      await tester.pump();

      expect(borderContainer, findsOneWidget);

      focusNode.unfocus();
      await tester.pump();
      await tester.pump();

      expect(borderContainer, findsNothing);
    });
  });
}
